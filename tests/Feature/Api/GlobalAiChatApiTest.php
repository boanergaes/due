<?php

use App\Models\Assignment;
use App\Models\CourseClass;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;

uses(RefreshDatabase::class);

test('api mentionables returns courses and assignments for sanctum client', function () {
    $user = User::factory()->genius()->create();
    Sanctum::actingAs($user, ['feature:core', 'feature:resources', 'feature:ai']);

    $class = CourseClass::factory()->create([
        'user_id' => $user->id,
        'course_name' => 'Linear Algebra',
    ]);
    $assignment = Assignment::factory()->create([
        'user_id' => $user->id,
        'class_id' => $class->id,
        'title' => 'Eigenvalues Lab',
        'deadline' => now()->addDays(2),
    ]);

    $response = $this->getJson('/api/v1/ai/mentionables');
    $response->assertOk()
        ->assertJsonStructure(['courses', 'assignments'])
        ->assertJsonFragment(['name' => 'Linear Algebra'])
        ->assertJsonFragment(['name' => 'Eigenvalues Lab']);
});

test('api global chat accepts mentions and returns assistant reply with token metrics', function () {
    $user = User::factory()->genius()->create();
    Sanctum::actingAs($user, ['feature:core', 'feature:resources', 'feature:ai']);

    $class = CourseClass::factory()->create([
        'user_id' => $user->id,
        'course_name' => 'Physics II',
    ]);

    $response = $this->postJson('/api/v1/ai/chat', [
        'message' => 'Help me prepare for @Physics II',
        'mentions' => [
            ['type' => 'course', 'id' => $class->id],
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
});

test('api clear conversation history empties messages', function () {
    $user = User::factory()->genius()->create();
    Sanctum::actingAs($user, ['feature:core', 'feature:resources', 'feature:ai']);

    $this->postJson('/api/v1/ai/chat', [
        'message' => 'Hello Copilot',
    ])->assertOk();

    $this->deleteJson('/api/v1/ai/history')
        ->assertOk()
        ->assertJson(['message' => 'Conversation history cleared.']);

    $messagesResponse = $this->getJson('/api/v1/ai/messages');
    expect($messagesResponse->json('messages'))->toHaveCount(0);
});
