<?php

namespace Tests\Feature;

use App\Enums\AssignmentStatus;
use App\Models\Assignment;
use App\Models\CourseClass;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Inertia\Testing\AssertableInertia as Assert;
use Tests\TestCase;

class DashboardTest extends TestCase
{
    use RefreshDatabase;

    public function test_guests_are_redirected_to_the_login_page(): void
    {
        $response = $this->get(route('dashboard'));
        $response->assertRedirect(route('login'));
    }

    public function test_authenticated_user_sees_empty_state_metrics(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)->get(route('dashboard'));

        $response->assertOk();
        $response->assertInertia(fn (Assert $page) => $page
            ->component('dashboard')
            ->where('metrics.total', 0)
            ->where('metrics.pending', 0)
            ->where('metrics.in_progress', 0)
            ->where('metrics.completed', 0)
            ->where('metrics.overdue', 0)
            ->where('metrics.due_today', 0)
            ->where('metrics.completion_rate', 0)
            ->where('metrics.on_time_rate', null)
            ->has('upcoming_assignments', 0)
            ->has('workload_by_class', 0)
        );
    }

    public function test_dashboard_calculates_correct_summary_and_urgency_metrics(): void
    {
        Carbon::setTestNow('2026-10-15 12:00:00');

        $user = User::factory()->create();
        $class = CourseClass::factory()->create([
            'user_id' => $user->id,
            'course_name' => 'Data Structures',
        ]);

        // 1. Pending assignment due in 3 days
        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Tree Project',
            'status' => AssignmentStatus::Pending,
            'deadline' => Carbon::parse('2026-10-18 17:00:00'),
        ]);

        // 2. In-progress assignment due today
        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Graph Quiz',
            'status' => AssignmentStatus::InProgress,
            'deadline' => Carbon::parse('2026-10-15 23:59:00'),
        ]);

        // 3. Overdue pending assignment
        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Lab 1',
            'status' => AssignmentStatus::Pending,
            'deadline' => Carbon::parse('2026-10-14 10:00:00'),
        ]);

        // 4. Completed on-time assignment
        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Homework 1',
            'status' => AssignmentStatus::Completed,
            'deadline' => Carbon::parse('2026-10-12 18:00:00'),
            'completed_at' => Carbon::parse('2026-10-12 16:00:00'),
        ]);

        // 5. Completed late assignment
        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Homework 2',
            'status' => AssignmentStatus::Completed,
            'deadline' => Carbon::parse('2026-10-10 18:00:00'),
            'completed_at' => Carbon::parse('2026-10-11 09:00:00'),
        ]);

        $response = $this->actingAs($user)->get(route('dashboard'));

        $response->assertOk();
        $response->assertInertia(fn (Assert $page) => $page
            ->component('dashboard')
            ->where('metrics.total', 5)
            ->where('metrics.pending', 2)
            ->where('metrics.in_progress', 1)
            ->where('metrics.completed', 2)
            ->where('metrics.overdue', 1)
            ->where('metrics.due_today', 1)
            ->where('metrics.completion_rate', 40) // 2 / 5 = 40%
            ->where('metrics.completed_on_time', 1)
            ->where('metrics.on_time_rate', 50) // 1 / 2 completed = 50%
            ->where('metrics.completed_recently', 2)
            ->has('upcoming_assignments', 2) // Tree Project + Graph Quiz
            ->has('workload_by_class', 1)
            ->where('workload_by_class.0.course_name', 'Data Structures')
            ->where('workload_by_class.0.total_assignments', 5)
            ->where('workload_by_class.0.active_assignments', 3)
            ->where('workload_by_class.0.completed_assignments', 2)
        );

        Carbon::setTestNow();
    }

    public function test_user_only_sees_their_own_dashboard_statistics(): void
    {
        Carbon::setTestNow('2026-10-15 12:00:00');

        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        $class1 = CourseClass::factory()->create(['user_id' => $user1->id, 'course_name' => 'Math']);
        $class2 = CourseClass::factory()->create(['user_id' => $user2->id, 'course_name' => 'Art']);

        Assignment::factory()->create([
            'user_id' => $user1->id,
            'class_id' => $class1->id,
            'title' => 'User 1 Task',
            'status' => AssignmentStatus::Pending,
            'deadline' => Carbon::parse('2026-10-20 12:00:00'),
        ]);

        Assignment::factory()->create([
            'user_id' => $user2->id,
            'class_id' => $class2->id,
            'title' => 'User 2 Secret Task',
            'status' => AssignmentStatus::Completed,
            'deadline' => Carbon::parse('2026-10-10 12:00:00'),
            'completed_at' => Carbon::parse('2026-10-09 12:00:00'),
        ]);

        $response = $this->actingAs($user1)->get(route('dashboard'));

        $response->assertInertia(fn (Assert $page) => $page
            ->where('metrics.total', 1)
            ->where('metrics.pending', 1)
            ->where('metrics.completed', 0)
            ->has('workload_by_class', 1)
            ->where('workload_by_class.0.course_name', 'Math')
            ->where('upcoming_assignments.0.title', 'User 1 Task')
        );

        Carbon::setTestNow();
    }
}
