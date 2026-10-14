<?php

use App\Enums\SubscriptionTier;
use App\Models\Assignment;
use App\Models\CourseClass;
use App\Models\Resource;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;

uses(RefreshDatabase::class);

beforeEach(function () {
    Storage::fake('local');
});

test('api can list resources for authenticated user', function () {
    $user = User::factory()->scholar()->create();
    Sanctum::actingAs($user, ['feature:core', 'feature:resources']);

    $class = CourseClass::factory()->create([
        'user_id' => $user->id,
        'course_name' => 'Computer Science',
    ]);
    $assignment = Assignment::factory()->create([
        'user_id' => $user->id,
        'class_id' => $class->id,
        'title' => 'Lab 1',
        'deadline' => now()->addDays(3),
    ]);

    Resource::factory()->create([
        'user_id' => $user->id,
        'resourceable_type' => CourseClass::class,
        'resourceable_id' => $class->id,
        'title' => 'Syllabus PDF',
    ]);

    Resource::factory()->create([
        'user_id' => $user->id,
        'resourceable_type' => Assignment::class,
        'resourceable_id' => $assignment->id,
        'title' => 'Rubric PDF',
    ]);

    $response = $this->getJson('/api/v1/resources');
    $response->assertOk()
        ->assertJsonCount(2, 'resources');

    // Filter by class
    $classFilterResponse = $this->getJson("/api/v1/resources?resourceable_type=class&resourceable_id={$class->id}");
    $classFilterResponse->assertOk()
        ->assertJsonCount(1, 'resources')
        ->assertJsonPath('resources.0.title', 'Syllabus PDF');

    // Filter by assignment
    $assignmentFilterResponse = $this->getJson("/api/v1/resources?resourceable_type=assignment&resourceable_id={$assignment->id}");
    $assignmentFilterResponse->assertOk()
        ->assertJsonCount(1, 'resources')
        ->assertJsonPath('resources.0.title', 'Rubric PDF');
});

test('api allows scholar user with feature:resources ability to upload resource', function () {
    $user = User::factory()->scholar()->create();
    Sanctum::actingAs($user, ['feature:core', 'feature:resources']);

    $class = CourseClass::factory()->create([
        'user_id' => $user->id,
        'course_name' => 'Computer Science',
    ]);
    $file = UploadedFile::fake()->create('lecture_slides.pdf', 300, 'application/pdf');

    $response = $this->postJson('/api/v1/resources', [
        'resourceable_type' => 'class',
        'resourceable_id' => $class->id,
        'title' => 'Lecture 1 Slides',
        'file' => $file,
    ]);

    $response->assertCreated()
        ->assertJson([
            'message' => 'Resource uploaded successfully.',
            'resource' => [
                'title' => 'Lecture 1 Slides',
                'file_name' => 'lecture_slides.pdf',
                'mime_type' => 'application/pdf',
                'is_pdf' => true,
            ],
        ]);

    expect(Resource::count())->toBe(1);
    $user->refresh();
    expect($user->storage_used_bytes)->toBeGreaterThan(0);
});

test('api denies free tier user without feature:resources ability with 403', function () {
    $freeUser = User::factory()->create(['subscription_tier' => SubscriptionTier::Free]);
    Sanctum::actingAs($freeUser, ['feature:core']);

    $class = CourseClass::factory()->create([
        'user_id' => $freeUser->id,
        'course_name' => 'General Physics',
    ]);
    $file = UploadedFile::fake()->create('notes.txt', 10, 'text/plain');

    $response = $this->postJson('/api/v1/resources', [
        'resourceable_type' => 'class',
        'resourceable_id' => $class->id,
        'title' => 'Lecture Notes',
        'file' => $file,
    ]);

    $response->assertForbidden()
        ->assertJson([
            'error' => 'Subscription upgrade required',
            'required_tier' => 'basic',
        ]);

    expect(Resource::count())->toBe(0);
});

test('api allows viewing resource metadata', function () {
    $user = User::factory()->scholar()->create();
    Sanctum::actingAs($user, ['feature:core', 'feature:resources']);

    $class = CourseClass::factory()->create([
        'user_id' => $user->id,
        'course_name' => 'Computer Science',
    ]);
    $resource = Resource::factory()->create([
        'user_id' => $user->id,
        'resourceable_type' => CourseClass::class,
        'resourceable_id' => $class->id,
        'title' => 'Course Overview',
        'extracted_text' => 'Important semester dates and grading policy.',
    ]);

    $response = $this->getJson("/api/v1/resources/{$resource->id}");
    $response->assertOk()
        ->assertJson([
            'resource' => [
                'id' => $resource->id,
                'title' => 'Course Overview',
                'has_extracted_text' => true,
                'extracted_text' => 'Important semester dates and grading policy.',
            ],
        ]);
});

test('api allows viewing and downloading file streams', function () {
    $user = User::factory()->scholar()->create();
    Sanctum::actingAs($user, ['feature:core', 'feature:resources']);

    $class = CourseClass::factory()->create([
        'user_id' => $user->id,
        'course_name' => 'Computer Science',
    ]);
    $file = UploadedFile::fake()->create('lab_guide.pdf', 200, 'application/pdf');

    $uploadResponse = $this->postJson('/api/v1/resources', [
        'resourceable_type' => 'class',
        'resourceable_id' => $class->id,
        'title' => 'Lab Guide',
        'file' => $file,
    ]);
    $resourceId = $uploadResponse->json('resource.id');

    // Inline stream view
    $viewResponse = $this->get("/api/v1/resources/{$resourceId}/view");
    $viewResponse->assertOk()
        ->assertHeader('Content-Type', 'application/pdf');

    // Attachment download stream
    $downloadResponse = $this->get("/api/v1/resources/{$resourceId}/download");
    $downloadResponse->assertOk();
});

test('api allows deleting resource and decrements user storage used', function () {
    $user = User::factory()->scholar()->create();
    Sanctum::actingAs($user, ['feature:core', 'feature:resources']);

    $class = CourseClass::factory()->create([
        'user_id' => $user->id,
        'course_name' => 'Computer Science',
    ]);
    $file = UploadedFile::fake()->create('dataset.csv', 1024, 'text/csv');

    $uploadResponse = $this->postJson('/api/v1/resources', [
        'resourceable_type' => 'class',
        'resourceable_id' => $class->id,
        'title' => 'Sample Dataset',
        'file' => $file,
    ]);
    $resourceId = $uploadResponse->json('resource.id');

    $deleteResponse = $this->deleteJson("/api/v1/resources/{$resourceId}");
    $deleteResponse->assertOk()
        ->assertJson(['message' => 'Resource deleted successfully.']);

    expect(Resource::count())->toBe(0);
    $user->refresh();
    expect($user->storage_used_bytes)->toBe(0);
});

test('api enforces cross-tenant isolation on resources', function () {
    $userA = User::factory()->scholar()->create();
    $userB = User::factory()->scholar()->create();

    $classA = CourseClass::factory()->create([
        'user_id' => $userA->id,
        'course_name' => 'Architecture 201',
    ]);
    $resourceA = Resource::factory()->create([
        'user_id' => $userA->id,
        'resourceable_type' => CourseClass::class,
        'resourceable_id' => $classA->id,
        'title' => 'User A Secret Syllabus',
    ]);

    // User B tries to view User A's resource details
    Sanctum::actingAs($userB, ['feature:core', 'feature:resources']);
    $this->getJson("/api/v1/resources/{$resourceA->id}")
        ->assertForbidden();

    // User B tries to view stream
    $this->get("/api/v1/resources/{$resourceA->id}/view")
        ->assertForbidden();

    // User B tries to download
    $this->get("/api/v1/resources/{$resourceA->id}/download")
        ->assertForbidden();

    // User B tries to delete
    $this->deleteJson("/api/v1/resources/{$resourceA->id}")
        ->assertForbidden();
});
