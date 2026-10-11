<?php

use App\Models\Assignment;
use App\Models\AssignmentNote;
use App\Models\CourseClass;

test('assignment note belongs to an assignment', function () {
    $course = CourseClass::factory()->create(['course_name' => 'Data Structures']);
    $assignment = Assignment::factory()->create([
        'class_id' => $course->id,
        'title' => 'Lab 1',
        'deadline' => now()->addDays(3),
    ]);
    $note = AssignmentNote::factory()->create([
        'assignment_id' => $assignment->id,
        'content' => 'First note content',
    ]);

    expect($note->assignment->id)->toBe($assignment->id)
        ->and($assignment->notes)->toHaveCount(1)
        ->and($assignment->notes->first()->id)->toBe($note->id);
});

test('assignment can have multiple notes', function () {
    $course = CourseClass::factory()->create(['course_name' => 'Data Structures']);
    $assignment = Assignment::factory()->create([
        'class_id' => $course->id,
        'title' => 'Lab 1',
        'deadline' => now()->addDays(3),
    ]);

    AssignmentNote::factory()->count(3)->create([
        'assignment_id' => $assignment->id,
        'content' => 'Sample note',
    ]);

    expect($assignment->notes)->toHaveCount(3);
});
