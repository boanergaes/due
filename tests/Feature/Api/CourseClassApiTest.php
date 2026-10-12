<?php

namespace Tests\Feature\Api;

use App\Models\Assignment;
use App\Models\CourseClass;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CourseClassApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_guest_cannot_access_classes_api(): void
    {
        $response = $this->getJson('/api/v1/classes');
        $response->assertUnauthorized();
    }

    public function test_user_can_list_their_classes_with_assignment_counts(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create([
            'user_id' => $user->id,
            'course_name' => 'Data Structures',
        ]);

        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Binary Trees',
            'deadline' => now()->addDays(3),
        ]);

        $token = $user->createToken('test')->plainTextToken;
        $response = $this->withToken($token)->getJson('/api/v1/classes');

        $response->assertOk();
        $response->assertJsonPath('data.0.course_name', 'Data Structures');
        $response->assertJsonPath('data.0.assignments_count', 1);
    }

    public function test_user_can_list_all_classes_with_all_flag(): void
    {
        $user = User::factory()->create();
        CourseClass::factory()->create([
            'user_id' => $user->id,
            'course_name' => 'Algorithms',
        ]);

        $token = $user->createToken('test')->plainTextToken;
        $response = $this->withToken($token)->getJson('/api/v1/classes?all=1');

        $response->assertOk();
        $response->assertJsonCount(1, 'data');
        $response->assertJsonPath('data.0.course_name', 'Algorithms');
    }

    public function test_user_can_create_a_class(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        $response = $this->withToken($token)->postJson('/api/v1/classes', [
            'course_name' => 'Machine Learning',
            'teacher_name' => 'Prof. Turing',
            'teacher_contact' => 'turing@uni.edu',
            'credit_hours' => 3,
            'ects' => 5,
        ]);

        $response->assertCreated();
        $response->assertJsonPath('data.course_name', 'Machine Learning');

        $this->assertDatabaseHas('classes', [
            'user_id' => $user->id,
            'course_name' => 'Machine Learning',
            'teacher_name' => 'Prof. Turing',
        ]);
    }

    public function test_user_can_view_a_class_and_its_assignments(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create([
            'user_id' => $user->id,
            'course_name' => 'Operating Systems',
        ]);

        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Page Replacement',
            'deadline' => now()->addDays(5),
        ]);

        $token = $user->createToken('test')->plainTextToken;
        $response = $this->withToken($token)->getJson("/api/v1/classes/{$class->id}");

        $response->assertOk();
        $response->assertJsonPath('data.course_name', 'Operating Systems');
        $response->assertJsonCount(1, 'data.assignments');
    }

    public function test_user_cannot_view_another_users_class(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $otherClass = CourseClass::factory()->create([
            'user_id' => $otherUser->id,
            'course_name' => 'Secret Class',
        ]);

        $token = $user->createToken('test')->plainTextToken;
        $response = $this->withToken($token)->getJson("/api/v1/classes/{$otherClass->id}");

        $response->assertForbidden();
    }

    public function test_user_can_update_their_class(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create([
            'user_id' => $user->id,
            'course_name' => 'Old Title',
        ]);

        $token = $user->createToken('test')->plainTextToken;
        $response = $this->withToken($token)->putJson("/api/v1/classes/{$class->id}", [
            'course_name' => 'New Title',
            'teacher_name' => 'Dr. Jones',
        ]);

        $response->assertOk();
        $response->assertJsonPath('data.course_name', 'New Title');

        $this->assertDatabaseHas('classes', [
            'id' => $class->id,
            'course_name' => 'New Title',
            'teacher_name' => 'Dr. Jones',
        ]);
    }

    public function test_user_cannot_update_another_users_class(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();
        $otherClass = CourseClass::factory()->create([
            'user_id' => $otherUser->id,
            'course_name' => 'Other Title',
        ]);

        $token = $user->createToken('test')->plainTextToken;
        $response = $this->withToken($token)->putJson("/api/v1/classes/{$otherClass->id}", [
            'course_name' => 'Hacked Title',
        ]);

        $response->assertForbidden();
    }

    public function test_user_can_delete_empty_class(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create([
            'user_id' => $user->id,
            'course_name' => 'Empty Course',
        ]);

        $token = $user->createToken('test')->plainTextToken;
        $response = $this->withToken($token)->deleteJson("/api/v1/classes/{$class->id}");

        $response->assertOk();
        $this->assertDatabaseMissing('classes', ['id' => $class->id]);
    }

    public function test_cannot_delete_class_with_associated_assignments(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create([
            'user_id' => $user->id,
            'course_name' => 'Active Course',
        ]);

        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Project',
            'deadline' => now()->addDays(5),
        ]);

        $token = $user->createToken('test')->plainTextToken;
        $response = $this->withToken($token)->deleteJson("/api/v1/classes/{$class->id}");

        $response->assertStatus(422);
        $response->assertJsonFragment([
            'message' => 'Cannot delete course "Active Course" because it has assignments associated with it. Please reassign or delete the assignments first.',
        ]);

        $this->assertDatabaseHas('classes', ['id' => $class->id]);
    }
}
