<?php

use App\Enums\SubscriptionTier;
use App\Models\Assignment;
use App\Models\CourseClass;
use App\Models\Resource;
use App\Models\User;
use App\Services\SubscriptionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Http;

uses(RefreshDatabase::class);

test('mentionables endpoint returns courses and assignments belonging to user', function () {
    $user = User::factory()->genius()->create();
    $class = CourseClass::factory()->create([
        'user_id' => $user->id,
        'course_name' => 'Algorithms & Complexity',
        'teacher_name' => 'Prof. Turing',
    ]);
    $assignment = Assignment::factory()->create([
        'user_id' => $user->id,
        'class_id' => $class->id,
        'title' => 'NP-Completeness Proofs',
        'deadline' => now()->addDays(4),
    ]);

    $passport = app(SubscriptionService::class)->generatePassport($user);

    $response = $this->actingAs($user)
        ->withSession(['subscription_passport' => $passport])
        ->getJson(route('ai.mentionables'));

    $response->assertOk()
        ->assertJsonStructure([
            'courses',
            'assignments',
        ])
        ->assertJsonFragment([
            'name' => 'Algorithms & Complexity',
            'type' => 'course',
        ])
        ->assertJsonFragment([
            'name' => 'NP-Completeness Proofs',
            'type' => 'assignment',
        ]);
});

test('global workspace ai chat resolves @mentioned course and assignment context', function () {
    config()->set('services.gemini.api_key', 'test-live-key');

    Http::fake([
        'generativelanguage.googleapis.com/*' => function (Request $request) {
            $body = $request->data();
            $systemInstruction = $body['system_instruction']['parts'][0]['text'] ?? '';

            // Verify that the mentioned course and assignment details were injected
            expect($systemInstruction)->toContain('Operating Systems');
            expect($systemInstruction)->toContain('Lab 3: Semaphores');
            expect($systemInstruction)->toContain('Producer-Consumer problem is required');

            return Http::response([
                'candidates' => [
                    [
                        'content' => [
                            'parts' => [
                                ['text' => 'For Lab 3 Semaphores in Operating Systems, ensure you initialize the empty semaphore to N and full to 0.'],
                            ],
                            'role' => 'model',
                        ],
                        'finishReason' => 'STOP',
                    ],
                ],
                'usageMetadata' => [
                    'promptTokenCount' => 250,
                    'candidatesTokenCount' => 30,
                    'totalTokenCount' => 280,
                ],
            ], 200);
        },
    ]);

    $user = User::factory()->genius()->create();
    $class = CourseClass::factory()->create([
        'user_id' => $user->id,
        'course_name' => 'Operating Systems',
    ]);
    $assignment = Assignment::factory()->create([
        'user_id' => $user->id,
        'class_id' => $class->id,
        'title' => 'Lab 3: Semaphores',
        'deadline' => now()->addDays(3),
    ]);

    Resource::factory()->create([
        'user_id' => $user->id,
        'resourceable_type' => Assignment::class,
        'resourceable_id' => $assignment->id,
        'title' => 'Lab Instructions',
        'file_name' => 'lab3_spec.txt',
        'extracted_text' => 'Producer-Consumer problem is required using POSIX semaphores.',
    ]);

    $passport = app(SubscriptionService::class)->generatePassport($user);

    $response = $this->actingAs($user)
        ->withSession(['subscription_passport' => $passport])
        ->postJson(route('ai.chat'), [
            'message' => 'How do I initialize semaphores for @Lab 3: Semaphores in @Operating Systems?',
            'mentions' => [
                ['type' => 'course', 'id' => $class->id],
                ['type' => 'assignment', 'id' => $assignment->id],
            ],
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

    expect($response->json('reply'))->toContain('initialize the empty semaphore');
    expect($response->json('context_sources'))->toContain('@Course: Operating Systems');
    expect($response->json('context_sources'))->toContain('@Assignment: Lab 3: Semaphores');
});

test('free and scholar users are blocked from global ai chat endpoints', function () {
    $freeUser = User::factory()->create(['subscription_tier' => SubscriptionTier::Free]);
    $freePassport = app(SubscriptionService::class)->generatePassport($freeUser);

    $this->actingAs($freeUser)
        ->withSession(['subscription_passport' => $freePassport])
        ->getJson(route('ai.mentionables'))
        ->assertForbidden();

    $this->actingAs($freeUser)
        ->withSession(['subscription_passport' => $freePassport])
        ->postJson(route('ai.chat'), ['message' => 'Help me'])
        ->assertForbidden();
});

test('cross-user isolation ensures a student cannot inject another users mentions', function () {
    $userA = User::factory()->genius()->create();
    $userB = User::factory()->genius()->create();

    $classB = CourseClass::factory()->create([
        'user_id' => $userB->id,
        'course_name' => 'User B Secret Course',
    ]);

    $passportA = app(SubscriptionService::class)->generatePassport($userA);

    // User A attempts to mention User B's class
    $response = $this->actingAs($userA)
        ->withSession(['subscription_passport' => $passportA])
        ->postJson(route('ai.chat'), [
            'message' => 'Tell me about @User B Secret Course',
            'mentions' => [
                ['type' => 'course', 'id' => $classB->id],
            ],
        ]);

    $response->assertOk();
    // User B's course was NOT included in context sources because User A does not own it
    expect($response->json('context_sources'))->not->toContain('@Course: User B Secret Course');
});
