<?php

namespace Tests\Feature\Notes;

use App\Models\Assignment;
use App\Models\AssignmentNote;
use App\Models\CourseClass;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AssignmentNoteCrudTest extends TestCase
{
    use RefreshDatabase;

    private function createAssignment(User $user): Assignment
    {
        $class = CourseClass::factory()->create([
            'user_id' => $user->id,
            'course_name' => 'Software Engineering',
        ]);

        return Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Sprint 1 Review',
            'deadline' => now()->addDays(5),
        ]);
    }

    public function test_guests_cannot_manage_notes(): void
    {
        $user = User::factory()->create();
        $assignment = $this->createAssignment($user);
        $note = AssignmentNote::factory()->create([
            'assignment_id' => $assignment->id,
            'content' => 'Sample note',
        ]);

        $this->post(route('assignments.notes.store', $assignment), ['content' => 'Note'])->assertRedirect(route('login'));
        $this->put(route('assignments.notes.update', [$assignment, $note]), ['content' => 'Updated'])->assertRedirect(route('login'));
        $this->delete(route('assignments.notes.destroy', [$assignment, $note]))->assertRedirect(route('login'));
    }

    public function test_user_can_add_multiple_notes_to_assignment(): void
    {
        $user = User::factory()->create();
        $assignment = $this->createAssignment($user);

        $this->actingAs($user)->post(route('assignments.notes.store', $assignment), [
            'content' => 'First note: check lecture slides 4-6.',
        ])->assertRedirect();

        $this->actingAs($user)->post(route('assignments.notes.store', $assignment), [
            'content' => 'Second note: ask TA during office hours.',
        ])->assertRedirect();

        $this->assertDatabaseCount('assignment_notes', 2);
        $this->assertEquals(2, $assignment->notes()->count());
    }

    public function test_adding_note_requires_content(): void
    {
        $user = User::factory()->create();
        $assignment = $this->createAssignment($user);

        $response = $this->actingAs($user)->post(route('assignments.notes.store', $assignment), [
            'content' => '',
        ]);

        $response->assertSessionHasErrors(['content']);
        $this->assertDatabaseCount('assignment_notes', 0);
    }

    public function test_user_cannot_add_note_to_another_users_assignment(): void
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        $assignment = $this->createAssignment($user1);

        $response = $this->actingAs($user2)->post(route('assignments.notes.store', $assignment), [
            'content' => 'Hacker note',
        ]);

        $response->assertForbidden();
        $this->assertDatabaseCount('assignment_notes', 0);
    }

    public function test_user_can_update_their_note(): void
    {
        $user = User::factory()->create();
        $assignment = $this->createAssignment($user);
        $note = AssignmentNote::factory()->create([
            'assignment_id' => $assignment->id,
            'content' => 'Draft version',
        ]);

        $response = $this->actingAs($user)->put(route('assignments.notes.update', [$assignment, $note]), [
            'content' => 'Final revised note.',
        ]);

        $response->assertRedirect();
        $this->assertDatabaseHas('assignment_notes', [
            'id' => $note->id,
            'content' => 'Final revised note.',
        ]);
    }

    public function test_user_cannot_update_another_users_note(): void
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        $assignment = $this->createAssignment($user1);
        $note = AssignmentNote::factory()->create([
            'assignment_id' => $assignment->id,
            'content' => 'Original note',
        ]);

        $response = $this->actingAs($user2)->put(route('assignments.notes.update', [$assignment, $note]), [
            'content' => 'Tampered note',
        ]);

        $response->assertForbidden();
        $this->assertDatabaseHas('assignment_notes', [
            'id' => $note->id,
            'content' => 'Original note',
        ]);
    }

    public function test_user_can_delete_their_note(): void
    {
        $user = User::factory()->create();
        $assignment = $this->createAssignment($user);
        $note = AssignmentNote::factory()->create([
            'assignment_id' => $assignment->id,
            'content' => 'To be deleted',
        ]);

        $response = $this->actingAs($user)->delete(route('assignments.notes.destroy', [$assignment, $note]));

        $response->assertRedirect();
        $this->assertDatabaseMissing('assignment_notes', [
            'id' => $note->id,
        ]);
    }

    public function test_user_cannot_delete_another_users_note(): void
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        $assignment = $this->createAssignment($user1);
        $note = AssignmentNote::factory()->create([
            'assignment_id' => $assignment->id,
            'content' => 'User1 private note',
        ]);

        $response = $this->actingAs($user2)->delete(route('assignments.notes.destroy', [$assignment, $note]));

        $response->assertForbidden();
        $this->assertDatabaseHas('assignment_notes', [
            'id' => $note->id,
        ]);
    }

    public function test_deleting_assignment_cascades_and_removes_notes(): void
    {
        $user = User::factory()->create();
        $assignment = $this->createAssignment($user);
        AssignmentNote::factory()->count(3)->sequence(
            ['content' => 'Note 1'],
            ['content' => 'Note 2'],
            ['content' => 'Note 3']
        )->create(['assignment_id' => $assignment->id]);

        $this->assertDatabaseCount('assignment_notes', 3);

        $this->actingAs($user)->delete(route('assignments.destroy', $assignment));

        $this->assertDatabaseMissing('assignments', ['id' => $assignment->id]);
        $this->assertDatabaseCount('assignment_notes', 0);
    }
}
