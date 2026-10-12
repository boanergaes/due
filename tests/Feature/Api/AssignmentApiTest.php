<?php

namespace Tests\Feature\Api;

use App\Enums\AssignmentStatus;
use App\Models\Assignment;
use App\Models\CourseClass;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AssignmentApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_guest_cannot_access_assignments_api(): void
    {
        $response = $this->getJson('/api/v1/assignments');
        $response->assertUnauthorized();
    }

    public function test_user_can_list_assignments_with_eager_class_and_urgency(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create([
            'user_id' => $user->id,
            'course_name' => 'Computer Networks',
        ]);

        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'TCP/IP Lab',
            'status' => AssignmentStatus::Pending,
            'deadline' => now()->addDays(2),
        ]);

        $token = $user->createToken('test')->plainTextToken;
        $response = $this->withToken($token)->getJson('/api/v1/assignments');

        $response->assertOk();
        $response->assertJsonPath('data.0.title', 'TCP/IP Lab');
        $response->assertJsonPath('data.0.course_class.course_name', 'Computer Networks');
        $this->assertNotNull($response->json('data.0.urgency'));
    }

    public function test_user_can_filter_assignments_by_search_and_status(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Math']);

        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Calculus Quiz',
            'status' => AssignmentStatus::Pending,
            'deadline' => now()->addDays(1),
        ]);

        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Linear Algebra Essay',
            'status' => AssignmentStatus::Completed,
            'deadline' => now()->addDays(5),
        ]);

        $token = $user->createToken('test')->plainTextToken;

        // Search test
        $responseSearch = $this->withToken($token)->getJson('/api/v1/assignments?search=Calculus');
        $responseSearch->assertOk();
        $responseSearch->assertJsonCount(1, 'data');
        $responseSearch->assertJsonPath('data.0.title', 'Calculus Quiz');

        // Status test
        $responseStatus = $this->withToken($token)->getJson('/api/v1/assignments?status=completed');
        $responseStatus->assertOk();
        $responseStatus->assertJsonCount(1, 'data');
        $responseStatus->assertJsonPath('data.0.title', 'Linear Algebra Essay');
    }

    public function test_user_can_create_assignment(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Physics']);

        $token = $user->createToken('test')->plainTextToken;
        $response = $this->withToken($token)->postJson('/api/v1/assignments', [
            'class_id' => $class->id,
            'title' => 'Quantum Mechanics HW',
            'description' => 'Solve chapters 1-3',
            'status' => 'pending',
            'deadline' => now()->addDays(7)->toDateTimeString(),
        ]);

        $response->assertCreated();
        $response->assertJsonPath('data.title', 'Quantum Mechanics HW');
        $response->assertJsonPath('data.course_class.course_name', 'Physics');

        $this->assertDatabaseHas('assignments', [
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Quantum Mechanics HW',
        ]);
    }

    public function test_user_cannot_create_assignment_for_another_users_class(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $otherClass = CourseClass::factory()->create(['user_id' => $otherUser->id, 'course_name' => 'Secret Class']);

        $token = $user->createToken('test')->plainTextToken;
        $response = $this->withToken($token)->postJson('/api/v1/assignments', [
            'class_id' => $otherClass->id,
            'title' => 'Unauthorized HW',
            'status' => 'pending',
            'deadline' => now()->addDays(7)->toDateTimeString(),
        ]);

        $response->assertUnprocessable();
        $response->assertJsonValidationErrors(['class_id']);
    }

    public function test_user_can_view_assignment_details(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'History']);
        $assignment = Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'WWI Essay',
            'deadline' => now()->addDays(4),
        ]);

        $token = $user->createToken('test')->plainTextToken;
        $response = $this->withToken($token)->getJson("/api/v1/assignments/{$assignment->id}");

        $response->assertOk();
        $response->assertJsonPath('data.title', 'WWI Essay');
        $response->assertJsonPath('data.course_class.course_name', 'History');
    }

    public function test_user_cannot_view_another_users_assignment(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $otherClass = CourseClass::factory()->create(['user_id' => $otherUser->id, 'course_name' => 'Other']);
        $otherAssignment = Assignment::factory()->create([
            'user_id' => $otherUser->id,
            'class_id' => $otherClass->id,
            'title' => 'Private',
            'deadline' => now()->addDays(4),
        ]);

        $token = $user->createToken('test')->plainTextToken;
        $response = $this->withToken($token)->getJson("/api/v1/assignments/{$otherAssignment->id}");

        $response->assertForbidden();
    }

    public function test_user_can_update_assignment(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Art']);
        $assignment = Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Painting Draft',
            'status' => AssignmentStatus::Pending,
            'deadline' => now()->addDays(4),
        ]);

        $token = $user->createToken('test')->plainTextToken;
        $response = $this->withToken($token)->putJson("/api/v1/assignments/{$assignment->id}", [
            'class_id' => $class->id,
            'title' => 'Final Painting',
            'status' => 'in_progress',
            'deadline' => now()->addDays(6)->toDateTimeString(),
        ]);

        $response->assertOk();
        $response->assertJsonPath('data.title', 'Final Painting');
        $response->assertJsonPath('data.status', 'in_progress');

        $this->assertDatabaseHas('assignments', [
            'id' => $assignment->id,
            'title' => 'Final Painting',
            'status' => 'in_progress',
        ]);
    }

    public function test_user_can_quick_update_status(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Biology']);
        $assignment = Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Dissection Report',
            'status' => AssignmentStatus::Pending,
            'completed_at' => null,
            'deadline' => now()->addDays(3),
        ]);

        $token = $user->createToken('test')->plainTextToken;
        $response = $this->withToken($token)->patchJson("/api/v1/assignments/{$assignment->id}/status", [
            'status' => 'completed',
        ]);

        $response->assertOk();
        $response->assertJsonPath('data.status', 'completed');
        $this->assertNotNull($response->json('data.completed_at'));

        $this->assertDatabaseHas('assignments', [
            'id' => $assignment->id,
            'status' => 'completed',
        ]);
    }

    public function test_user_can_delete_assignment(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Chemistry']);
        $assignment = Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Lab Report',
            'deadline' => now()->addDays(2),
        ]);

        $token = $user->createToken('test')->plainTextToken;
        $response = $this->withToken($token)->deleteJson("/api/v1/assignments/{$assignment->id}");

        $response->assertOk();
        $this->assertDatabaseMissing('assignments', ['id' => $assignment->id]);
    }
}
