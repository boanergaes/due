<?php

namespace Tests\Feature\Assignments;

use App\Enums\AssignmentStatus;
use App\Models\Assignment;
use App\Models\CourseClass;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Inertia\Testing\AssertableInertia as Assert;
use Tests\TestCase;

class AssignmentFilterTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_search_assignments_by_title_or_description(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Computer Science']);

        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Operating System Threading Lab',
            'description' => 'Write a POSIX threads synchronization program.',
            'deadline' => now()->addDays(5),
        ]);

        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Calculus Homework',
            'description' => 'Integration by parts problem set.',
            'deadline' => now()->addDays(2),
        ]);

        // Search by title keyword
        $response = $this->actingAs($user)->get(route('assignments.index', ['search' => 'Threading']));
        $response->assertOk();
        $response->assertInertia(fn (Assert $page) => $page
            ->has('assignments.data', 1)
            ->where('assignments.data.0.title', 'Operating System Threading Lab')
        );

        // Search by description keyword
        $response = $this->actingAs($user)->get(route('assignments.index', ['search' => 'Integration']));
        $response->assertOk();
        $response->assertInertia(fn (Assert $page) => $page
            ->has('assignments.data', 1)
            ->where('assignments.data.0.title', 'Calculus Homework')
        );
    }

    public function test_can_filter_assignments_by_date_range(): void
    {
        Carbon::setTestNow('2026-10-15 12:00:00');

        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Data Science']);

        // Due Oct 16
        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Task A',
            'deadline' => Carbon::parse('2026-10-16 10:00:00'),
        ]);

        // Due Oct 20
        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Task B',
            'deadline' => Carbon::parse('2026-10-20 15:00:00'),
        ]);

        // Due Oct 25
        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Task C',
            'deadline' => Carbon::parse('2026-10-25 23:59:00'),
        ]);

        // Filter between Oct 18 and Oct 22
        $response = $this->actingAs($user)->get(route('assignments.index', [
            'start_date' => '2026-10-18',
            'end_date' => '2026-10-22',
        ]));

        $response->assertOk();
        $response->assertInertia(fn (Assert $page) => $page
            ->has('assignments.data', 1)
            ->where('assignments.data.0.title', 'Task B')
        );

        Carbon::setTestNow();
    }

    public function test_rejects_end_date_earlier_than_start_date(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)
            ->from(route('assignments.index'))
            ->get(route('assignments.index', [
                'start_date' => '2026-10-25',
                'end_date' => '2026-10-20',
            ]));

        $response->assertSessionHasErrors(['end_date']);
    }

    public function test_can_filter_by_urgency_presets(): void
    {
        Carbon::setTestNow('2026-10-15 12:00:00');

        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Physics']);

        // Overdue assignment
        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Overdue Task',
            'status' => AssignmentStatus::Pending,
            'deadline' => Carbon::parse('2026-10-14 18:00:00'),
        ]);

        // Due today assignment
        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Due Today Task',
            'status' => AssignmentStatus::InProgress,
            'deadline' => Carbon::parse('2026-10-15 20:00:00'),
        ]);

        // Future upcoming assignment (in 5 days)
        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Future Task',
            'status' => AssignmentStatus::Pending,
            'deadline' => Carbon::parse('2026-10-20 12:00:00'),
        ]);

        // Test overdue filter
        $response = $this->actingAs($user)->get(route('assignments.index', ['urgency' => 'overdue']));
        $response->assertInertia(fn (Assert $page) => $page
            ->has('assignments.data', 1)
            ->where('assignments.data.0.title', 'Overdue Task')
        );

        // Test due_today filter
        $response = $this->actingAs($user)->get(route('assignments.index', ['urgency' => 'due_today']));
        $response->assertInertia(fn (Assert $page) => $page
            ->has('assignments.data', 1)
            ->where('assignments.data.0.title', 'Due Today Task')
        );

        // Test upcoming filter (returns tasks from now onwards)
        $response = $this->actingAs($user)->get(route('assignments.index', ['urgency' => 'upcoming']));
        $response->assertInertia(fn (Assert $page) => $page
            ->has('assignments.data', 2)
        );

        Carbon::setTestNow();
    }

    public function test_can_combine_search_status_class_and_urgency_filters(): void
    {
        Carbon::setTestNow('2026-10-15 12:00:00');

        $user = User::factory()->create();
        $math = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Math']);
        $chem = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Chemistry']);

        // Target match
        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $math->id,
            'title' => 'Math Midterm Review',
            'status' => AssignmentStatus::InProgress,
            'deadline' => Carbon::parse('2026-10-18 10:00:00'),
        ]);

        // Same class, different status
        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $math->id,
            'title' => 'Math Problem Set',
            'status' => AssignmentStatus::Completed,
            'deadline' => Carbon::parse('2026-10-18 10:00:00'),
        ]);

        // Different class
        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $chem->id,
            'title' => 'Chemistry Midterm Review',
            'status' => AssignmentStatus::InProgress,
            'deadline' => Carbon::parse('2026-10-18 10:00:00'),
        ]);

        $response = $this->actingAs($user)->get(route('assignments.index', [
            'search' => 'Midterm',
            'class_id' => $math->id,
            'status' => 'in_progress',
            'urgency' => 'upcoming',
        ]));

        $response->assertInertia(fn (Assert $page) => $page
            ->has('assignments.data', 1)
            ->where('assignments.data.0.title', 'Math Midterm Review')
        );

        Carbon::setTestNow();
    }
}
