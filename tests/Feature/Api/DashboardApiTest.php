<?php

namespace Tests\Feature\Api;

use App\Enums\AssignmentStatus;
use App\Models\Assignment;
use App\Models\CourseClass;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DashboardApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_guest_cannot_access_dashboard_api(): void
    {
        $response = $this->getJson('/api/v1/dashboard');
        $response->assertUnauthorized();
    }

    public function test_authenticated_user_receives_accurate_metrics_and_upcoming_assignments(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'CS 101']);

        // Create 1 pending, 1 in_progress, 1 completed, 1 overdue
        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Assignment 1',
            'status' => AssignmentStatus::Pending,
            'deadline' => now()->addDays(2),
        ]);

        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Assignment 2',
            'status' => AssignmentStatus::InProgress,
            'deadline' => now()->addDays(5),
        ]);

        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Assignment 3',
            'status' => AssignmentStatus::Completed,
            'completed_at' => now(),
            'deadline' => now()->addDays(1),
        ]);

        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Assignment 4',
            'status' => AssignmentStatus::Pending,
            'deadline' => now()->subDay(),
        ]);

        // Other user's assignment (must not be counted)
        $otherUser = User::factory()->create();
        $otherClass = CourseClass::factory()->create([
            'user_id' => $otherUser->id,
            'course_name' => 'Other Course',
        ]);
        Assignment::factory()->create([
            'user_id' => $otherUser->id,
            'class_id' => $otherClass->id,
            'title' => 'Other Assignment',
            'status' => AssignmentStatus::Pending,
            'deadline' => now()->addDays(3),
        ]);

        $token = $user->createToken('test')->plainTextToken;
        $response = $this->withToken($token)->getJson('/api/v1/dashboard');

        $response->assertOk();
        $response->assertJsonStructure([
            'metrics' => [
                'total',
                'pending',
                'in_progress',
                'completed',
                'overdue',
                'due_today',
                'completion_rate',
            ],
            'upcoming_assignments',
            'overdue_assignments',
            'workload_by_class',
        ]);

        $this->assertEquals(4, $response->json('metrics.total'));
        $this->assertEquals(2, $response->json('metrics.pending'));
        $this->assertEquals(1, $response->json('metrics.in_progress'));
        $this->assertEquals(1, $response->json('metrics.completed'));
        $this->assertEquals(1, $response->json('metrics.overdue'));

        // Check computed urgency is present in JSON
        $upcoming = $response->json('upcoming_assignments');
        $this->assertNotEmpty($upcoming);
        $this->assertArrayHasKey('urgency', $upcoming[0]);
        $this->assertArrayHasKey('label', $upcoming[0]['urgency']);
    }
}
