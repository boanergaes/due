<?php

use App\Enums\SubscriptionTier;
use App\Models\Assignment;
use App\Models\CourseClass;
use App\Models\Resource;
use App\Models\User;
use App\Services\SubscriptionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

uses(RefreshDatabase::class);

beforeEach(function () {
    Storage::fake('local');
});

test('scholar user can upload a study resource to a class', function () {
    $user = User::factory()->scholar()->create();
    $class = CourseClass::factory()->create([
        'user_id' => $user->id,
        'course_name' => 'Data Structures 101',
    ]);

    // Give user in-session passport for Web
    $passport = app(SubscriptionService::class)->generatePassport($user);

    $file = UploadedFile::fake()->create('syllabus.pdf', 1024, 'application/pdf');

    $response = $this->actingAs($user)
        ->withSession(['subscription_passport' => $passport])
        ->post(route('resources.upload'), [
            'resourceable_type' => 'class',
            'resourceable_id' => $class->id,
            'title' => 'Course Syllabus',
            'file' => $file,
        ]);

    $response->assertRedirect();
    $response->assertSessionHas('success');

    $this->assertDatabaseHas('resources', [
        'user_id' => $user->id,
        'resourceable_type' => CourseClass::class,
        'resourceable_id' => $class->id,
        'title' => 'Course Syllabus',
        'file_name' => 'syllabus.pdf',
        'mime_type' => 'application/pdf',
    ]);

    $user->refresh();
    expect($user->storage_used_bytes)->toBeGreaterThan(0);
});

test('scholar user can upload an image resource to an assignment', function () {
    $user = User::factory()->scholar()->create();
    $class = CourseClass::factory()->create([
        'user_id' => $user->id,
        'course_name' => 'Algorithms',
    ]);
    $assignment = Assignment::factory()->create([
        'user_id' => $user->id,
        'class_id' => $class->id,
        'title' => 'Graph Traversal Lab',
        'deadline' => now()->addDays(5),
    ]);

    $passport = app(SubscriptionService::class)->generatePassport($user);
    $file = UploadedFile::fake()->image('diagram.png', 800, 600);

    $response = $this->actingAs($user)
        ->withSession(['subscription_passport' => $passport])
        ->post(route('resources.upload'), [
            'resourceable_type' => 'assignment',
            'resourceable_id' => $assignment->id,
            'title' => 'Graph Diagram',
            'file' => $file,
        ]);

    $response->assertRedirect();
    $response->assertSessionHas('success');

    $resource = Resource::where('title', 'Graph Diagram')->first();
    expect($resource)->not->toBeNull();
    expect($resource->isImage())->toBeTrue();
    expect($resource->resourceable_id)->toBe($assignment->id);
});

test('free tier user is blocked from uploading study resources', function () {
    $freeUser = User::factory()->create([
        'subscription_tier' => SubscriptionTier::Free,
    ]);
    $class = CourseClass::factory()->create([
        'user_id' => $freeUser->id,
        'course_name' => 'Physics 101',
    ]);

    $passport = app(SubscriptionService::class)->generatePassport($freeUser);
    $file = UploadedFile::fake()->create('notes.txt', 10, 'text/plain');

    $response = $this->actingAs($freeUser)
        ->withSession(['subscription_passport' => $passport])
        ->post(route('resources.upload'), [
            'resourceable_type' => 'class',
            'resourceable_id' => $class->id,
            'title' => 'Lecture Notes',
            'file' => $file,
        ]);

    $response->assertRedirect(route('pricing'));
    expect(Resource::count())->toBe(0);

    // JSON / AJAX request receives 403 Forbidden
    $jsonResponse = $this->actingAs($freeUser)
        ->withSession(['subscription_passport' => $passport])
        ->postJson(route('resources.upload'), [
            'resourceable_type' => 'class',
            'resourceable_id' => $class->id,
            'title' => 'Lecture Notes',
            'file' => $file,
        ]);

    $jsonResponse->assertForbidden();
});

test('resource upload extracts text from plain text files', function () {
    $user = User::factory()->genius()->create();
    $class = CourseClass::factory()->create([
        'user_id' => $user->id,
        'course_name' => 'Computer Systems',
    ]);

    $passport = app(SubscriptionService::class)->generatePassport($user);
    $textContent = "Professor remarks:\nSection 3.2 on virtual memory is required for exam.\nIgnore appendix B.";
    $file = UploadedFile::fake()->createWithContent('remarks.txt', $textContent);

    $this->actingAs($user)
        ->withSession(['subscription_passport' => $passport])
        ->post(route('resources.upload'), [
            'resourceable_type' => 'class',
            'resourceable_id' => $class->id,
            'title' => 'Exam Remarks',
            'file' => $file,
        ]);

    $resource = Resource::where('title', 'Exam Remarks')->first();
    expect($resource)->not->toBeNull();
    expect($resource->extracted_text)->toContain('virtual memory is required');
});

test('owner can view and download their resource while unauthorized user is denied', function () {
    $userA = User::factory()->scholar()->create();
    $userB = User::factory()->scholar()->create();

    $class = CourseClass::factory()->create([
        'user_id' => $userA->id,
        'course_name' => 'Calculus II',
    ]);

    $passportA = app(SubscriptionService::class)->generatePassport($userA);
    $passportB = app(SubscriptionService::class)->generatePassport($userB);

    $file = UploadedFile::fake()->create('cheat_sheet.pdf', 500, 'application/pdf');

    $this->actingAs($userA)
        ->withSession(['subscription_passport' => $passportA])
        ->post(route('resources.upload'), [
            'resourceable_type' => 'class',
            'resourceable_id' => $class->id,
            'title' => 'Formulas Sheet',
            'file' => $file,
        ]);

    $resource = Resource::where('title', 'Formulas Sheet')->first();
    expect($resource)->not->toBeNull();

    // User A can stream inline view
    $viewResponse = $this->actingAs($userA)
        ->get(route('resources.view', $resource));
    $viewResponse->assertOk();
    $viewResponse->assertHeader('Content-Type', 'application/pdf');

    // User A can download
    $downloadResponse = $this->actingAs($userA)
        ->get(route('resources.download', $resource));
    $downloadResponse->assertOk();

    // User B cannot view User A's resource (403)
    $this->actingAs($userB)
        ->withSession(['subscription_passport' => $passportB])
        ->get(route('resources.view', $resource))
        ->assertForbidden();

    // User B cannot delete User A's resource (403)
    $this->actingAs($userB)
        ->withSession(['subscription_passport' => $passportB])
        ->delete(route('resources.destroy', $resource))
        ->assertForbidden();
});

test('deleting a resource removes file and recalculates user storage bytes', function () {
    $user = User::factory()->scholar()->create();
    $class = CourseClass::factory()->create([
        'user_id' => $user->id,
        'course_name' => 'Chemistry',
    ]);

    $passport = app(SubscriptionService::class)->generatePassport($user);
    $file = UploadedFile::fake()->create('lab_report.pdf', 2048, 'application/pdf');

    $this->actingAs($user)
        ->withSession(['subscription_passport' => $passport])
        ->post(route('resources.upload'), [
            'resourceable_type' => 'class',
            'resourceable_id' => $class->id,
            'title' => 'Lab Report',
            'file' => $file,
        ]);

    $resource = Resource::where('title', 'Lab Report')->first();
    $filePath = $resource->file_path;
    expect(Storage::disk('local')->exists($filePath))->toBeTrue();

    $user->refresh();
    $initialStorage = $user->storage_used_bytes;
    expect($initialStorage)->toBeGreaterThan(0);

    // Delete resource
    $deleteResponse = $this->actingAs($user)
        ->withSession(['subscription_passport' => $passport])
        ->delete(route('resources.destroy', $resource));

    $deleteResponse->assertRedirect();
    expect(Resource::where('title', 'Lab Report')->exists())->toBeFalse();
    expect(Storage::disk('local')->exists($filePath))->toBeFalse();

    $user->refresh();
    expect($user->storage_used_bytes)->toBe(0);
});
