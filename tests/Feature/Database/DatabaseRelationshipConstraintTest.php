<?php

use App\Models\Assignment;
use App\Models\AssignmentNote;
use App\Models\CourseClass;
use App\Models\User;
use Illuminate\Database\QueryException;

test('deleting a class that has assignments is restricted by database constraint', function () {
    $course = CourseClass::factory()->create(['course_name' => 'Algorithms']);
    Assignment::factory()->create([
        'class_id' => $course->id,
        'title' => 'Homework 1',
        'deadline' => now()->addDays(2),
    ]);

    expect(fn () => $course->delete())->toThrow(QueryException::class);
});

test('deleting an assignment cascades and deletes its notes', function () {
    $course = CourseClass::factory()->create(['course_name' => 'Databases']);
    $assignment = Assignment::factory()->create([
        'class_id' => $course->id,
        'title' => 'Project 1',
        'deadline' => now()->addDays(2),
    ]);
    $note = AssignmentNote::factory()->create([
        'assignment_id' => $assignment->id,
        'content' => 'First note',
    ]);

    $assignment->delete();

    expect(AssignmentNote::find($note->id))->toBeNull();
});

test('deleting a user cascades and deletes all their classes and assignments', function () {
    $user = User::factory()->create();
    $course = CourseClass::factory()->create([
        'user_id' => $user->id,
        'course_name' => 'Systems',
    ]);
    $assignment = Assignment::factory()->create([
        'user_id' => $user->id,
        'class_id' => $course->id,
        'title' => 'Lab 1',
        'deadline' => now()->addDays(2),
    ]);

    $user->delete();

    expect(CourseClass::find($course->id))->toBeNull()
        ->and(Assignment::find($assignment->id))->toBeNull();
});
