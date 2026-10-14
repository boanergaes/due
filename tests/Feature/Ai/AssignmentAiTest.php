<?php

use App\Enums\SubscriptionTier;
use App\Models\Assignment;
use App\Models\AssignmentNote;
use App\Models\CourseClass;
use App\Models\Resource;
use App\Models\User;
use App\Services\SubscriptionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;

uses(RefreshDatabase::class);

test('genius user can retrieve ai study session and context sources', function () {
    $user = User::factory()->genius()->create();
    $class = CourseClass::factory()->create([
        'user_id' => $user->id,
        'course_name' => 'Data Structures',
    ]);
    $assignment = Assignment::factory()->create([
        'user_id' => $user->id,
        'class_id' => $class->id,
        'title' => 'Binary Search Trees',
        'deadline' => now()->addDays(5),
    ]);

    AssignmentNote::factory()->create([
        'assignment_id' => $assignment->id,
        'content' => 'Remember AVL tree rotations.',
    ]);

    Resource::factory()->create([
        'user_id' => $user->id,
        'resourceable_type' => Assignment::class,
        'resourceable_id' => $assignment->id,
        'title' => 'Lab Spec',
        'file_name' => 'bst_spec.pdf',
        'extracted_text' => 'Section 1.2 requires implementing left and right rotate.',
    ]);

    $passport = app(SubscriptionService::class)->generatePassport($user);

    $response = $this->actingAs($user)
        ->withSession(['subscription_passport' => $passport])
        ->getJson(route('assignments.ai.messages', $assignment));

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
                'bst_spec.pdf',
            ],
        ]);
});

test('free and scholar tiers are blocked from ai assistant on web', function () {
    $freeUser = User::factory()->create(['subscription_tier' => SubscriptionTier::Free]);
    $scholarUser = User::factory()->scholar()->create();

    $class = CourseClass::factory()->create([
        'user_id' => $freeUser->id,
        'course_name' => 'Algorithms',
    ]);
    $assignment = Assignment::factory()->create([
        'user_id' => $freeUser->id,
        'class_id' => $class->id,
        'title' => 'Dynamic Programming',
        'deadline' => now()->addDays(2),
    ]);

    $freePassport = app(SubscriptionService::class)->generatePassport($freeUser);
    $scholarPassport = app(SubscriptionService::class)->generatePassport($scholarUser);

    // Free user gets redirected to pricing or 403 on json
    $this->actingAs($freeUser)
        ->withSession(['subscription_passport' => $freePassport])
        ->get(route('assignments.ai.messages', $assignment))
        ->assertRedirect(route('pricing'));

    $this->actingAs($freeUser)
        ->withSession(['subscription_passport' => $freePassport])
        ->getJson(route('assignments.ai.messages', $assignment))
        ->assertForbidden();

    // Scholar user also blocked from AI feature
    $this->actingAs($scholarUser)
        ->withSession(['subscription_passport' => $scholarPassport])
        ->getJson(route('assignments.ai.messages', $assignment))
        ->assertForbidden();
});

test('genius user can send message and receive ai response with fallback simulation', function () {
    $user = User::factory()->genius()->create();
    $class = CourseClass::factory()->create([
        'user_id' => $user->id,
        'course_name' => 'Computer Networks',
    ]);
    $assignment = Assignment::factory()->create([
        'user_id' => $user->id,
        'class_id' => $class->id,
        'title' => 'TCP Congestion Control',
        'deadline' => now()->addDays(3),
    ]);

    $passport = app(SubscriptionService::class)->generatePassport($user);

    $response = $this->actingAs($user)
        ->withSession(['subscription_passport' => $passport])
        ->postJson(route('assignments.ai.chat', $assignment), [
            'message' => 'What is the difference between Tahoe and Reno?',
        ]);

    $response->assertOk()
        ->assertJsonStructure([
            'reply',
            'tokens_used',
            'model',
            'context_sources',
            'user_message',
            'assistant_message',
        ]);

    expect($response->json('user_message.content'))->toBe('What is the difference between Tahoe and Reno?');
    expect($response->json('assistant_message.role'))->toBe('assistant');
    expect($response->json('tokens_used'))->toBeGreaterThan(0);
});

test('gemini api live integration handles api responses cleanly', function () {
    config()->set('services.gemini.api_key', 'test-live-key');
    config()->set('services.gemini.model', 'gemini-1.5-flash');

    Http::fake([
        'generativelanguage.googleapis.com/*' => Http::response([
            'candidates' => [
                [
                    'content' => [
                        'parts' => [
                            ['text' => 'TCP Tahoe sets congestion window to 1 upon packet loss, whereas Reno cuts it in half (Fast Recovery).'],
                        ],
                        'role' => 'model',
                    ],
                    'finishReason' => 'STOP',
                ],
            ],
            'usageMetadata' => [
                'promptTokenCount' => 150,
                'candidatesTokenCount' => 28,
                'totalTokenCount' => 178,
            ],
        ], 200),
    ]);

    $user = User::factory()->genius()->create();
    $class = CourseClass::factory()->create([
        'user_id' => $user->id,
        'course_name' => 'Computer Networks',
    ]);
    $assignment = Assignment::factory()->create([
        'user_id' => $user->id,
        'class_id' => $class->id,
        'title' => 'TCP Congestion Control',
        'deadline' => now()->addDays(3),
    ]);

    $passport = app(SubscriptionService::class)->generatePassport($user);

    $response = $this->actingAs($user)
        ->withSession(['subscription_passport' => $passport])
        ->postJson(route('assignments.ai.chat', $assignment), [
            'message' => 'Explain Fast Recovery in TCP Reno.',
        ]);

    $response->assertOk()
        ->assertJson([
            'reply' => 'TCP Tahoe sets congestion window to 1 upon packet loss, whereas Reno cuts it in half (Fast Recovery).',
            'tokens_used' => 178,
            'model' => 'gemini-1.5-flash',
        ]);
});

test('user can clear conversation history', function () {
    $user = User::factory()->genius()->create();
    $class = CourseClass::factory()->create([
        'user_id' => $user->id,
        'course_name' => 'Calculus III',
    ]);
    $assignment = Assignment::factory()->create([
        'user_id' => $user->id,
        'class_id' => $class->id,
        'title' => 'Vector Fields',
        'deadline' => now()->addDays(4),
    ]);

    $passport = app(SubscriptionService::class)->generatePassport($user);

    // Send a message first
    $this->actingAs($user)
        ->withSession(['subscription_passport' => $passport])
        ->postJson(route('assignments.ai.chat', $assignment), [
            'message' => 'What is Green theorem?',
        ])->assertOk();

    // Verify messages exist
    $messagesResponse = $this->actingAs($user)
        ->withSession(['subscription_passport' => $passport])
        ->getJson(route('assignments.ai.messages', $assignment));
    expect($messagesResponse->json('messages'))->toHaveCount(2);

    // Clear history
    $this->actingAs($user)
        ->withSession(['subscription_passport' => $passport])
        ->deleteJson(route('assignments.ai.clear', $assignment))
        ->assertOk()
        ->assertJson(['message' => 'Conversation history cleared.']);

    // Verify messages are now empty
    $emptyResponse = $this->actingAs($user)
        ->withSession(['subscription_passport' => $passport])
        ->getJson(route('assignments.ai.messages', $assignment));
    expect($emptyResponse->json('messages'))->toHaveCount(0);
});

test('cross-user tenant isolation prevents accessing other users ai conversation', function () {
    $userA = User::factory()->genius()->create();
    $userB = User::factory()->genius()->create();

    $classA = CourseClass::factory()->create([
        'user_id' => $userA->id,
        'course_name' => 'Class A',
    ]);
    $assignmentA = Assignment::factory()->create([
        'user_id' => $userA->id,
        'class_id' => $classA->id,
        'title' => 'Assignment A',
        'deadline' => now()->addDays(1),
    ]);

    $passportB = app(SubscriptionService::class)->generatePassport($userB);

    $this->actingAs($userB)
        ->withSession(['subscription_passport' => $passportB])
        ->getJson(route('assignments.ai.messages', $assignmentA))
        ->assertNotFound();

    $this->actingAs($userB)
        ->withSession(['subscription_passport' => $passportB])
        ->postJson(route('assignments.ai.chat', $assignmentA), ['message' => 'Hi'])
        ->assertNotFound();
});
