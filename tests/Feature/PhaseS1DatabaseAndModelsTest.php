<?php

use App\Enums\SubscriptionStatus;
use App\Enums\SubscriptionTier;
use App\Enums\UserRole;
use App\Models\AiConversation;
use App\Models\AiMessage;
use App\Models\Assignment;
use App\Models\CourseClass;
use App\Models\Resource;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

test('user model has subscription tier and role attributes and helper methods', function () {
    $student = User::factory()->create([
        'role' => UserRole::Student,
        'subscription_tier' => SubscriptionTier::Free,
    ]);

    expect($student->isSuperAdmin())->toBeFalse();
    expect($student->hasFeature(SubscriptionTier::FEATURE_CORE))->toBeTrue();
    expect($student->hasFeature(SubscriptionTier::FEATURE_RESOURCES))->toBeFalse();
    expect($student->hasFeature(SubscriptionTier::FEATURE_AI))->toBeFalse();
    expect($student->canUploadResource(100))->toBeFalse();

    $scholar = User::factory()->scholar()->create();
    expect($scholar->subscription_tier)->toBe(SubscriptionTier::Basic);
    expect($scholar->hasFeature(SubscriptionTier::FEATURE_RESOURCES))->toBeTrue();
    expect($scholar->hasFeature(SubscriptionTier::FEATURE_AI))->toBeFalse();
    expect($scholar->canUploadResource(1024))->toBeTrue();

    $genius = User::factory()->genius()->create();
    expect($genius->subscription_tier)->toBe(SubscriptionTier::Premium);
    expect($genius->hasFeature(SubscriptionTier::FEATURE_AI))->toBeTrue();
    expect($genius->hasFeature(SubscriptionTier::FEATURE_RESOURCES))->toBeTrue();

    $superAdmin = User::factory()->superAdmin()->create();
    expect($superAdmin->isSuperAdmin())->toBeTrue();
    expect($superAdmin->hasFeature(SubscriptionTier::FEATURE_RESOURCES))->toBeTrue();
    expect($superAdmin->hasFeature(SubscriptionTier::FEATURE_AI))->toBeTrue();
    expect($superAdmin->canUploadResource(999_999_999))->toBeTrue();
});

test('user can have multiple subscriptions and retrieves active subscription', function () {
    $user = User::factory()->create();

    $oldSubscription = Subscription::factory()->cancelled()->create([
        'user_id' => $user->id,
        'tier' => SubscriptionTier::Basic,
        'starts_at' => now()->subMonths(2),
        'ends_at' => now()->subMonth(),
    ]);

    $activeSubscription = Subscription::factory()->genius()->create([
        'user_id' => $user->id,
        'status' => SubscriptionStatus::Active,
        'starts_at' => now(),
        'ends_at' => now()->addMonth(),
    ]);

    expect($user->subscriptions)->toHaveCount(2);
    expect($user->activeSubscription->id)->toBe($activeSubscription->id);
    expect($user->activeSubscription->tier)->toBe(SubscriptionTier::Premium);
    expect($user->activeSubscription->status)->toBe(SubscriptionStatus::Active);
});

test('resource polymorphic relationship works with course classes and assignments', function () {
    $user = User::factory()->create();
    $class = CourseClass::factory()->create([
        'user_id' => $user->id,
        'course_name' => 'Data Structures and Algorithms',
    ]);
    $assignment = Assignment::factory()->create([
        'user_id' => $user->id,
        'class_id' => $class->id,
        'title' => 'Binary Search Tree Implementation',
        'deadline' => now()->addDays(7),
    ]);

    $classResource = Resource::factory()->forClass($class)->create([
        'file_name' => 'syllabus.pdf',
        'mime_type' => 'application/pdf',
        'file_size_bytes' => 1024 * 500, // 500KB
    ]);

    $assignmentResource = Resource::factory()->image()->forAssignment($assignment)->create([
        'file_name' => 'diagram.png',
        'file_size_bytes' => 1024 * 1024 * 2, // 2MB
    ]);

    expect($class->resources)->toHaveCount(1);
    expect($class->resources->first()->file_name)->toBe('syllabus.pdf');
    expect($class->resources->first()->isPdf())->toBeTrue();
    expect($class->resources->first()->isImage())->toBeFalse();
    expect($class->resources->first()->formattedSize())->toBe('500 KB');

    expect($assignment->resources)->toHaveCount(1);
    expect($assignment->resources->first()->file_name)->toBe('diagram.png');
    expect($assignment->resources->first()->isImage())->toBeTrue();
    expect($assignment->resources->first()->formattedSize())->toBe('2.0 MB');

    // Test storage calculation helper on User model
    expect($user->recalculateStorageUsed())->toBe((1024 * 500) + (1024 * 1024 * 2));
    expect($user->storage_used_bytes)->toBe((1024 * 500) + (1024 * 1024 * 2));
});

test('assignment can have ai study conversations with ordered messages', function () {
    $user = User::factory()->create();
    $class = CourseClass::factory()->create([
        'user_id' => $user->id,
        'course_name' => 'Operating Systems',
    ]);
    $assignment = Assignment::factory()->create([
        'user_id' => $user->id,
        'class_id' => $class->id,
        'title' => 'Lab 3: CPU Scheduling',
        'deadline' => now()->addDays(3),
    ]);

    $conversation = AiConversation::factory()->create([
        'user_id' => $user->id,
        'assignment_id' => $assignment->id,
        'title' => 'Operating Systems Review',
    ]);

    $msg1 = AiMessage::factory()->user()->create([
        'conversation_id' => $conversation->id,
        'content' => 'What is the Round Robin algorithm?',
        'created_at' => now()->subMinute(),
    ]);

    $msg2 = AiMessage::factory()->assistant()->create([
        'conversation_id' => $conversation->id,
        'content' => 'Round Robin is a preemptive CPU scheduling algorithm...',
        'created_at' => now(),
    ]);

    expect($assignment->aiConversations)->toHaveCount(1);
    expect($assignment->latestAiConversation->id)->toBe($conversation->id);
    expect($conversation->messages)->toHaveCount(2);
    expect($conversation->messages->first()->id)->toBe($msg1->id);
    expect($conversation->messages->last()->id)->toBe($msg2->id);
    expect($conversation->messages->first()->role)->toBe('user');
    expect($conversation->messages->last()->role)->toBe('assistant');
});
