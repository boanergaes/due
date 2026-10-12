<?php

namespace Tests\Feature\Api;

use App\Models\Assignment;
use App\Models\CourseClass;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AssignmentNoteApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_guest_cannot_access_notes_api(): void
    {
        $response = $this->getJson('/api/v1/assignments/1/notes');
        $response->assertUnauthorized();
    }

    public function test_user_can_list_notes_for_their_assignment(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Math']);
        $assignment = Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Homework 1',
            'deadline' => now()->addDays(2),
        ]);

        $assignment->notes()->create(['content' => 'Review chapter 2']);

        $token = $user->createToken('test')->plainTextToken;
        $response = $this->withToken($token)->getJson("/api/v1/assignments/{$assignment->id}/notes");

        $response->assertOk();
        $response->assertJsonCount(1, 'data');
        $response->assertJsonPath('data.0.content', 'Review chapter 2');
    }

    public function test_user_cannot_list_notes_for_another_users_assignment(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $otherClass = CourseClass::factory()->create(['user_id' => $otherUser->id, 'course_name' => 'Other']);
        $otherAssignment = Assignment::factory()->create([
            'user_id' => $otherUser->id,
            'class_id' => $otherClass->id,
            'title' => 'Secret HW',
            'deadline' => now()->addDays(2),
        ]);

        $token = $user->createToken('test')->plainTextToken;
        $response = $this->withToken($token)->getJson("/api/v1/assignments/{$otherAssignment->id}/notes");

        $response->assertForbidden();
    }

    public function test_user_can_create_a_note(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'English']);
        $assignment = Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Book Report',
            'deadline' => now()->addDays(4),
        ]);

        $token = $user->createToken('test')->plainTextToken;
        $response = $this->withToken($token)->postJson("/api/v1/assignments/{$assignment->id}/notes", [
            'content' => 'Remember to cite sources in MLA format',
        ]);

        $response->assertCreated();
        $response->assertJsonPath('data.content', 'Remember to cite sources in MLA format');

        $this->assertDatabaseHas('assignment_notes', [
            'assignment_id' => $assignment->id,
            'content' => 'Remember to cite sources in MLA format',
        ]);
    }

    public function test_user_cannot_create_note_on_another_users_assignment(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $otherClass = CourseClass::factory()->create(['user_id' => $otherUser->id, 'course_name' => 'Other']);
        $otherAssignment = Assignment::factory()->create([
            'user_id' => $otherUser->id,
            'class_id' => $otherClass->id,
            'title' => 'Other HW',
            'deadline' => now()->addDays(2),
        ]);

        $token = $user->createToken('test')->plainTextToken;
        $response = $this->withToken($token)->postJson("/api/v1/assignments/{$otherAssignment->id}/notes", [
            'content' => 'Malicious note',
        ]);

        $response->assertForbidden();
    }

    public function test_user_can_update_their_note(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Philosophy']);
        $assignment = Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Essay',
            'deadline' => now()->addDays(4),
        ]);
        $note = $assignment->notes()->create(['content' => 'Original note']);

        $token = $user->createToken('test')->plainTextToken;
        $response = $this->withToken($token)->putJson("/api/v1/assignments/{$assignment->id}/notes/{$note->id}", [
            'content' => 'Updated note content',
        ]);

        $response->assertOk();
        $response->assertJsonPath('data.content', 'Updated note content');

        $this->assertDatabaseHas('assignment_notes', [
            'id' => $note->id,
            'content' => 'Updated note content',
        ]);
    }

    public function test_updating_note_with_mismatched_assignment_is_forbidden(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Logic']);
        $assignment1 = Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'HW 1',
            'deadline' => now()->addDays(2),
        ]);
        $assignment2 = Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'HW 2',
            'deadline' => now()->addDays(4),
        ]);
        $noteOnFirst = $assignment1->notes()->create(['content' => 'Note on 1']);

        $token = $user->createToken('test')->plainTextToken;
        // Attempt to update note 1 via assignment 2 endpoint
        $response = $this->withToken($token)->putJson("/api/v1/assignments/{$assignment2->id}/notes/{$noteOnFirst->id}", [
            'content' => 'Attempted hijack',
        ]);

        $response->assertForbidden();
    }

    public function test_user_can_delete_their_note(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'French']);
        $assignment = Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Vocab Quiz',
            'deadline' => now()->addDays(2),
        ]);
        $note = $assignment->notes()->create(['content' => 'Temporary memo']);

        $token = $user->createToken('test')->plainTextToken;
        $response = $this->withToken($token)->deleteJson("/api/v1/assignments/{$assignment->id}/notes/{$note->id}");

        $response->assertOk();
        $this->assertDatabaseMissing('assignment_notes', ['id' => $note->id]);
    }
}
