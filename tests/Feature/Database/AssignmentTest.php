<?php

use App\Enums\AssignmentStatus;
use App\Models\Assignment;
use App\Models\CourseClass;
use App\Models\User;
use Carbon\CarbonInterface;

test('assignment belongs to a user and a class', function () {
    $user = User::factory()->create();
    $course = CourseClass::factory()->create([
        'user_id' => $user->id,
        'course_name' => 'Data Structures',
    ]);

    $assignment = Assignment::factory()->create([
        'user_id' => $user->id,
        'class_id' => $course->id,
        'title' => 'Lab 1',
        'deadline' => now()->addDays(5),
    ]);

    expect($assignment->user->id)->toBe($user->id)
        ->and($assignment->class->id)->toBe($course->id)
        ->and($assignment->courseClass->id)->toBe($course->id)
        ->and($user->assignments)->toHaveCount(1)
        ->and($course->assignments)->toHaveCount(1);
});

test('assignment casts status to enum and dates to carbon instances', function () {
    $course = CourseClass::factory()->create(['course_name' => 'Operating Systems']);

    $assignment = Assignment::factory()->create([
        'class_id' => $course->id,
        'title' => 'Memory Assignment',
        'status' => 'in_progress',
        'deadline' => '2026-10-15 14:00:00',
        'completed_at' => '2026-10-15 13:30:00',
    ]);

    expect($assignment->status)->toBe(AssignmentStatus::InProgress)
        ->and($assignment->deadline)->toBeInstanceOf(CarbonInterface::class)
        ->and($assignment->completed_at)->toBeInstanceOf(CarbonInterface::class);
});

test('assignment query scopes filter by status correctly', function () {
    $user = User::factory()->create();
    $course = CourseClass::factory()->create([
        'user_id' => $user->id,
        'course_name' => 'Computer Networks',
    ]);

    Assignment::factory()->create([
        'user_id' => $user->id,
        'class_id' => $course->id,
        'title' => 'Assignment 1',
        'deadline' => now()->addDays(2),
        'status' => AssignmentStatus::Pending,
    ]);

    Assignment::factory()->inProgress()->create([
        'user_id' => $user->id,
        'class_id' => $course->id,
        'title' => 'Assignment 2',
        'deadline' => now()->addDays(3),
    ]);

    Assignment::factory()->completed()->create([
        'user_id' => $user->id,
        'class_id' => $course->id,
        'title' => 'Assignment 3',
        'deadline' => now()->addDays(1),
    ]);

    expect(Assignment::pending()->count())->toBe(1)
        ->and(Assignment::inProgress()->count())->toBe(1)
        ->and(Assignment::completed()->count())->toBe(1);
});

test('assignment factory states work as expected', function () {
    $course = CourseClass::factory()->create(['course_name' => 'Algorithms']);

    $completed = Assignment::factory()->completed()->create([
        'class_id' => $course->id,
        'title' => 'Completed Task',
        'deadline' => now()->subDay(),
    ]);
    expect($completed->status)->toBe(AssignmentStatus::Completed)
        ->and($completed->completed_at)->not->toBeNull();

    $overdue = Assignment::factory()->overdue()->create([
        'class_id' => $course->id,
        'title' => 'Overdue Task',
    ]);
    expect($overdue->deadline->isPast())->toBeTrue()
        ->and($overdue->status)->toBe(AssignmentStatus::Pending);

    $dueToday = Assignment::factory()->dueToday()->create([
        'class_id' => $course->id,
        'title' => 'Task Due Today',
    ]);
    expect($dueToday->deadline->isToday())->toBeTrue();
});
