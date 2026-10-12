<?php

namespace Tests\Feature\Assignments;

use App\Enums\AssignmentStatus;
use App\Models\Assignment;
use App\Models\CourseClass;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class AssignmentQueryPerformanceTest extends TestCase
{
    use RefreshDatabase;

    public function test_assignments_index_does_not_suffer_from_n_plus_one_query_problem(): void
    {
        $user = User::factory()->create();

        // Scenario A: 2 assignments across 2 different classes
        $classA1 = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Math']);
        $classA2 = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Physics']);

        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $classA1->id,
            'title' => 'Math 1',
            'deadline' => now()->addDays(2),
        ]);
        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $classA2->id,
            'title' => 'Physics 1',
            'deadline' => now()->addDays(3),
        ]);

        DB::flushQueryLog();
        DB::enableQueryLog();

        $this->actingAs($user)->get(route('assignments.index'));

        $queryCountWithTwoAssignments = count(DB::getQueryLog());
        DB::disableQueryLog();

        // Scenario B: Add 8 more assignments across 4 new classes
        for ($i = 3; $i <= 6; $i++) {
            $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => "Subject {$i}"]);
            Assignment::factory()->create([
                'user_id' => $user->id,
                'class_id' => $class->id,
                'title' => "Task A {$i}",
                'deadline' => now()->addDays($i),
            ]);
            Assignment::factory()->create([
                'user_id' => $user->id,
                'class_id' => $class->id,
                'title' => "Task B {$i}",
                'deadline' => now()->addDays($i + 1),
            ]);
        }

        DB::flushQueryLog();
        DB::enableQueryLog();

        $this->actingAs($user)->get(route('assignments.index'));

        $queryCountWithTenAssignments = count(DB::getQueryLog());
        DB::disableQueryLog();

        // If eager loading with('courseClass') is working, query count remains constant!
        // Without eager loading, it would execute 1 additional query per row (8 more queries).
        $this->assertSame(
            $queryCountWithTwoAssignments,
            $queryCountWithTenAssignments,
            "Query count increased from {$queryCountWithTwoAssignments} to {$queryCountWithTenAssignments}. An N+1 query problem is present."
        );
    }

    public function test_dashboard_query_count_remains_constant_regardless_of_assignment_volume(): void
    {
        $user = User::factory()->create();

        // Baseline: 2 assignments and 1 class
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Architecture']);
        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Design Draft',
            'status' => AssignmentStatus::Pending,
            'deadline' => now()->addDays(2),
        ]);
        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Review',
            'status' => AssignmentStatus::Completed,
            'deadline' => now()->subDay(),
            'completed_at' => now()->subDays(2),
        ]);

        DB::flushQueryLog();
        DB::enableQueryLog();

        $this->actingAs($user)->get(route('dashboard'));

        $baselineQueries = count(DB::getQueryLog());
        DB::disableQueryLog();

        // Add 10 more assignments
        for ($i = 1; $i <= 10; $i++) {
            Assignment::factory()->create([
                'user_id' => $user->id,
                'class_id' => $class->id,
                'title' => "Extra Task {$i}",
                'status' => AssignmentStatus::Pending,
                'deadline' => now()->addDays($i + 1),
            ]);
        }

        DB::flushQueryLog();
        DB::enableQueryLog();

        $this->actingAs($user)->get(route('dashboard'));

        $scaledQueries = count(DB::getQueryLog());
        DB::disableQueryLog();

        // Asserts that aggregates and eager-loaded upcoming feed do not scale queries linearly with data volume
        $this->assertSame(
            $baselineQueries,
            $scaledQueries,
            "Dashboard queries scaled with assignment count ({$baselineQueries} vs {$scaledQueries}). Check for N+1 queries."
        );
    }
}
