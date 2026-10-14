<?php

use App\Enums\SubscriptionTier;
use App\Models\Assignment;
use App\Models\AssignmentNote;
use App\Models\CourseClass;
use App\Models\Resource;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Laravel\Sanctum\Sanctum;

uses(RefreshDatabase::class);

test('api can retrieve ai conversation and context sources with feature:ai ability', function () {
    $user = User::factory()->genius()->create();
    Sanctum::actingAs($user, ['feature:core', 'feature:resources', 'feature:ai']);

    $class = CourseClass::factory()->create([
        'user_id' => $user->id,
        'course_name' => 'Database Systems',
    ]);
    $assignment = Assignment::factory()->create([
        'user_id' => $user->id,
        'class_id' => $class->id,
        'title' => 'SQL Indexing Optimization',
        'deadline' => now()->addDays(4),
    ]);

    AssignmentNote::factory()->create([
        'assignment_id' => $assignment->id,
        'content' => 'Review B-Tree vs Hash index performance.',
    ]);

    Resource::factory()->create([
        'user_id' => $user->id,
        'resourceable_type' => Assignment::class,
        'resourceable_id' => $assignment->id,
        'title' => 'Lab Guide',
        'file_name' => 'lab_guide.pdf',
        'extracted_text' => 'Part 2 tests EXPLAIN ANALYZE on 100k rows.',
    ]);

    $response = $this->getJson("/api/v1/assignments/{$assignment->id}/ai/messages");

    $response->assertOk()
        ->assertJsonStructure([
            'conversation_id',
            'context_sources',
            'total_tokens',
            'messages',
        ])
        ->assertJsonFragment([
            'context_sources' => [
                'Assignment Details',
                '1 Assignment Note',
                'lab_guide.pdf',
            ],
        ]);
});

test('api denies users without feature:ai ability with 403', function () {
    // 1. Free tier
    $freeUser = User::factory()->create(['subscription_tier' => SubscriptionTier::Free]);
    Sanctum::actingAs($freeUser, ['feature:core']);

    $class = CourseClass::factory()->create([
        'user_id' => $freeUser->id,
        'course_name' => 'Math',
    ]);
    $assignment = Assignment::factory()->create([
        'user_id' => $freeUser->id,
        'class_id' => $class->id,
        'title' => 'Problem Set 1',
        'deadline' => now()->addDays(2),
    ]);

    $this->getJson("/api/v1/assignments/{$assignment->id}/ai/messages")
        ->assertForbidden()
        ->assertJson([
            'error' => 'Subscription upgrade required',
            'required_tier' => 'premium',
        ]);

    $this->postJson("/api/v1/assignments/{$assignment->id}/ai/chat", ['message' => 'Help me'])
        ->assertForbidden()
        ->assertJson([
            'error' => 'Subscription upgrade required',
            'required_tier' => 'premium',
        ]);

    // 2. Scholar tier (has resources, but not AI)
    $scholarUser = User::factory()->scholar()->create();
    Sanctum::actingAs($scholarUser, ['feature:core', 'feature:resources']);

    $this->getJson("/api/v1/assignments/{$assignment->id}/ai/messages")
        ->assertForbidden();
});

test('api can post chat message and get response with token telemetry', function () {
    config()->set('services.gemini.api_key', 'test-api-key');

    Http::fake([
        'generativelanguage.googleapis.com/*' => Http::response([
            'candidates' => [
                [
                    'content' => [
                        'parts' => [
                            ['text' => 'B-Tree indexes are best for range queries, while Hash indexes excel at exact lookups.'],
                        ],
                        'role' => 'model',
                    ],
                    'finishReason' => 'STOP',
                ],
            ],
            'usageMetadata' => [
                'promptTokenCount' => 200,
                'candidatesTokenCount' => 35,
                'totalTokenCount' => 235,
            ],
        ], 200),
    ]);

    $user = User::factory()->genius()->create();
    Sanctum::actingAs($user, ['feature:core', 'feature:resources', 'feature:ai']);

    $class = CourseClass::factory()->create([
        'user_id' => $user->id,
        'course_name' => 'Database Systems',
    ]);
    $assignment = Assignment::factory()->create([
        'user_id' => $user->id,
        'class_id' => $class->id,
        'title' => 'SQL Indexing',
        'deadline' => now()->addDays(3),
    ]);

    $response = $this->postJson("/api/v1/assignments/{$assignment->id}/ai/chat", [
        'message' => 'When should I choose B-Tree over Hash?',
    ]);

    $response->assertOk()
        ->assertJson([
            'reply' => 'B-Tree indexes are best for range queries, while Hash indexes excel at exact lookups.',
            'tokens_used' => 235,
            'model' => 'gemini-2.5-flash',
        ]);
});

test('api can clear conversation history', function () {
    $user = User::factory()->genius()->create();
    Sanctum::actingAs($user, ['feature:core', 'feature:resources', 'feature:ai']);

    $class = CourseClass::factory()->create([
        'user_id' => $user->id,
        'course_name' => 'Philosophy',
    ]);
    $assignment = Assignment::factory()->create([
        'user_id' => $user->id,
        'class_id' => $class->id,
        'title' => 'Ethics Essay',
        'deadline' => now()->addDays(3),
    ]);

    // Send chat
    $this->postJson("/api/v1/assignments/{$assignment->id}/ai/chat", [
        'message' => 'Summarize utilitarianism.',
    ])->assertOk();

    // Verify messages exist
    $response = $this->getJson("/api/v1/assignments/{$assignment->id}/ai/messages");
    expect($response->json('messages'))->toHaveCount(2);

    // Delete history
    $deleteResponse = $this->deleteJson("/api/v1/assignments/{$assignment->id}/ai/history");
    $deleteResponse->assertOk()
        ->assertJson(['message' => 'Conversation history cleared.']);

    // Verify messages now empty
    $responseAfter = $this->getJson("/api/v1/assignments/{$assignment->id}/ai/messages");
    expect($responseAfter->json('messages'))->toHaveCount(0);
});

test('api enforces tenant isolation on ai endpoints', function () {
    $userA = User::factory()->genius()->create();
    $userB = User::factory()->genius()->create();

    $classA = CourseClass::factory()->create([
        'user_id' => $userA->id,
        'course_name' => 'Class A',
    ]);
    $assignmentA = Assignment::factory()->create([
        'user_id' => $userA->id,
        'class_id' => $classA->id,
        'title' => 'Secret Assignment A',
        'deadline' => now()->addDays(1),
    ]);

    Sanctum::actingAs($userB, ['feature:core', 'feature:resources', 'feature:ai']);

    $this->getJson("/api/v1/assignments/{$assignmentA->id}/ai/messages")
        ->assertNotFound();

    $this->postJson("/api/v1/assignments/{$assignmentA->id}/ai/chat", ['message' => 'Hello'])
        ->assertNotFound();

    $this->deleteJson("/api/v1/assignments/{$assignmentA->id}/ai/history")
        ->assertNotFound();
});
