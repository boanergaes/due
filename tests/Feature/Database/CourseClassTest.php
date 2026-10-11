<?php

use App\Models\CourseClass;
use App\Models\User;

test('course class belongs to a user', function () {
    $user = User::factory()->create();
    $course = CourseClass::factory()->create([
        'user_id' => $user->id,
        'course_name' => 'Algorithms',
    ]);

    expect($course->user->id)->toBe($user->id);
    expect($user->classes)->toHaveCount(1);
    expect($user->classes->first()->id)->toBe($course->id);
});

test('course class casts numeric fields properly', function () {
    $course = CourseClass::factory()->create([
        'course_name' => 'Database Systems',
        'credit_hours' => 3.5,
        'ects' => 6.0,
    ]);

    expect($course->credit_hours)->toBe(3.5);
    expect($course->ects)->toBe(6.0);
});

test('course class can have nullable fields', function () {
    $user = User::factory()->create();
    $course = CourseClass::create([
        'user_id' => $user->id,
        'course_name' => 'Independent Study',
        'teacher_name' => null,
        'teacher_contact' => null,
        'credit_hours' => null,
        'ects' => null,
    ]);

    expect($course->course_name)->toBe('Independent Study')
        ->and($course->teacher_name)->toBeNull()
        ->and($course->teacher_contact)->toBeNull()
        ->and($course->credit_hours)->toBeNull()
        ->and($course->ects)->toBeNull();
});
