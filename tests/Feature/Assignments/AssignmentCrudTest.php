<?php

namespace Tests\Feature\Assignments;

use App\Enums\AssignmentStatus;
use App\Models\Assignment;
use App\Models\CourseClass;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AssignmentCrudTest extends TestCase
{
    use RefreshDatabase;

    public function test_guests_cannot_access_assignments_pages(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Algorithms']);
        $assignment = Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Lab 1',
            'deadline' => now()->addDays(3),
        ]);

        $this->get(route('assignments.index'))->assertRedirect(route('login'));
        $this->get(route('assignments.create'))->assertRedirect(route('login'));
        $this->post(route('assignments.store'), ['title' => 'Test'])->assertRedirect(route('login'));
        $this->get(route('assignments.show', $assignment))->assertRedirect(route('login'));
        $this->get(route('assignments.edit', $assignment))->assertRedirect(route('login'));
        $this->put(route('assignments.update', $assignment), ['title' => 'Updated'])->assertRedirect(route('login'));
        $this->patch(route('assignments.update-status', $assignment), ['status' => 'completed'])->assertRedirect(route('login'));
        $this->delete(route('assignments.destroy', $assignment))->assertRedirect(route('login'));
    }

    public function test_user_can_view_assignments_index(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Data Structures']);

        Assignment::factory()->count(3)->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Homework',
            'deadline' => now()->addDays(2),
        ]);

        $response = $this->actingAs($user)->get(route('assignments.index'));

        $response->assertOk();
    }

    public function test_user_can_filter_assignments_by_status_and_class(): void
    {
        $user = User::factory()->create();
        $class1 = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Math']);
        $class2 = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Physics']);

        $pendingMath = Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class1->id,
            'title' => 'Math Problem Set',
            'status' => AssignmentStatus::Pending,
            'deadline' => now()->addDays(1),
        ]);

        $completedPhysics = Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class2->id,
            'title' => 'Physics Lab',
            'status' => AssignmentStatus::Completed,
            'deadline' => now()->addDays(2),
        ]);

        // Filter by status=pending
        $response = $this->actingAs($user)->get(route('assignments.index', ['status' => 'pending']));
        $response->assertOk();

        // Filter by class_id
        $response = $this->actingAs($user)->get(route('assignments.index', ['class_id' => $class1->id]));
        $response->assertOk();
    }

    public function test_user_can_create_assignment_for_their_class(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Computer Networks']);

        $deadline = now()->addDays(7)->startOfMinute();

        $response = $this->actingAs($user)->post(route('assignments.store'), [
            'class_id' => $class->id,
            'title' => 'Packet Sniffer Project',
            'description' => 'Build a simple sniffer using Wireshark.',
            'status' => AssignmentStatus::InProgress->value,
            'deadline' => $deadline->toDateTimeString(),
        ]);

        $response->assertRedirect(route('assignments.index'));
        $this->assertDatabaseHas('assignments', [
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Packet Sniffer Project',
            'status' => AssignmentStatus::InProgress->value,
        ]);
    }

    public function test_user_cannot_create_assignment_for_another_users_class(): void
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        $otherClass = CourseClass::factory()->create(['user_id' => $user2->id, 'course_name' => 'Foreign Course']);

        $response = $this->actingAs($user1)->post(route('assignments.store'), [
            'class_id' => $otherClass->id,
            'title' => 'Illegal Assignment',
            'status' => AssignmentStatus::Pending->value,
            'deadline' => now()->addDays(3)->toDateTimeString(),
        ]);

        $response->assertSessionHasErrors(['class_id']);
        $this->assertDatabaseCount('assignments', 0);
    }

    public function test_creating_assignment_requires_title_class_status_and_deadline(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)->post(route('assignments.store'), []);

        $response->assertSessionHasErrors(['title', 'class_id', 'status', 'deadline']);
    }

    public function test_user_can_view_their_assignment(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'AI']);
        $assignment = Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Neural Net Training',
            'deadline' => now()->addDays(5),
        ]);

        $response = $this->actingAs($user)->get(route('assignments.show', $assignment));

        $response->assertOk();
    }

    public function test_user_cannot_view_another_users_assignment(): void
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        $class = CourseClass::factory()->create(['user_id' => $user1->id, 'course_name' => 'Security']);
        $assignment = Assignment::factory()->create([
            'user_id' => $user1->id,
            'class_id' => $class->id,
            'title' => 'Exploit Lab',
            'deadline' => now()->addDays(2),
        ]);

        $response = $this->actingAs($user2)->get(route('assignments.show', $assignment));

        $response->assertForbidden();
    }

    public function test_user_can_update_their_assignment(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Compilers']);
        $assignment = Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Lexer',
            'status' => AssignmentStatus::Pending,
            'deadline' => now()->addDays(4),
        ]);

        $response = $this->actingAs($user)->put(route('assignments.update', $assignment), [
            'class_id' => $class->id,
            'title' => 'Parser & AST',
            'description' => 'Recursive descent parser.',
            'status' => AssignmentStatus::InProgress->value,
            'deadline' => now()->addDays(6)->toDateTimeString(),
        ]);

        $response->assertRedirect(route('assignments.index'));
        $this->assertDatabaseHas('assignments', [
            'id' => $assignment->id,
            'title' => 'Parser & AST',
            'status' => AssignmentStatus::InProgress->value,
        ]);
    }

    public function test_user_cannot_update_another_users_assignment(): void
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        $class = CourseClass::factory()->create(['user_id' => $user1->id, 'course_name' => 'Compilers']);
        $assignment = Assignment::factory()->create([
            'user_id' => $user1->id,
            'class_id' => $class->id,
            'title' => 'Lexer',
            'deadline' => now()->addDays(4),
        ]);

        $response = $this->actingAs($user2)->put(route('assignments.update', $assignment), [
            'class_id' => $class->id,
            'title' => 'Hacked Lexer',
            'status' => AssignmentStatus::Completed->value,
            'deadline' => now()->addDays(6)->toDateTimeString(),
        ]);

        $response->assertForbidden();
        $this->assertDatabaseHas('assignments', [
            'id' => $assignment->id,
            'title' => 'Lexer',
        ]);
    }

    public function test_user_can_quick_update_assignment_status(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Databases']);
        $assignment = Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Index Optimization',
            'status' => AssignmentStatus::InProgress,
            'completed_at' => null,
            'deadline' => now()->addDays(1),
        ]);

        $response = $this->actingAs($user)->patch(route('assignments.update-status', $assignment), [
            'status' => AssignmentStatus::Completed->value,
        ]);

        $response->assertRedirect();
        $assignment->refresh();
        $this->assertEquals(AssignmentStatus::Completed, $assignment->status);
        $this->assertNotNull($assignment->completed_at);

        // Reverting to pending clears completed_at
        $this->actingAs($user)->patch(route('assignments.update-status', $assignment), [
            'status' => AssignmentStatus::Pending->value,
        ]);

        $assignment->refresh();
        $this->assertEquals(AssignmentStatus::Pending, $assignment->status);
        $this->assertNull($assignment->completed_at);
    }

    public function test_user_can_delete_their_assignment(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Math']);
        $assignment = Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Old Assignment',
            'deadline' => now()->addDays(3),
        ]);

        $response = $this->actingAs($user)->delete(route('assignments.destroy', $assignment));

        $response->assertRedirect(route('assignments.index'));
        $this->assertDatabaseMissing('assignments', [
            'id' => $assignment->id,
        ]);
    }

    public function test_user_cannot_delete_another_users_assignment(): void
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        $class = CourseClass::factory()->create(['user_id' => $user1->id, 'course_name' => 'Math']);
        $assignment = Assignment::factory()->create([
            'user_id' => $user1->id,
            'class_id' => $class->id,
            'title' => 'User1 Assignment',
            'deadline' => now()->addDays(3),
        ]);

        $response = $this->actingAs($user2)->delete(route('assignments.destroy', $assignment));

        $response->assertForbidden();
        $this->assertDatabaseHas('assignments', [
            'id' => $assignment->id,
        ]);
    }
}
