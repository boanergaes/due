<?php

namespace Tests\Unit\Services;

use App\Enums\AssignmentStatus;
use App\Models\Assignment;
use App\Models\CourseClass;
use App\Models\User;
use App\Services\DeadlineUrgencyService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class DeadlineUrgencyServiceTest extends TestCase
{
    use RefreshDatabase;

    private DeadlineUrgencyService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new DeadlineUrgencyService();
    }

    public function test_assignment_past_deadline_is_overdue(): void
    {
        $frozenNow = Carbon::parse('2026-10-15 14:00:00');
        Carbon::setTestNow($frozenNow);

        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Algorithms']);

        $assignment = Assignment::factory()->create([
            'title' => 'Test Assignment',
            'user_id' => $user->id,
            'class_id' => $class->id,
            'status' => AssignmentStatus::Pending,
            'deadline' => Carbon::parse('2026-10-15 12:00:00'), // 2 hours ago
        ]);

        $result = $this->service->calculate($assignment, $frozenNow);

        $this->assertEquals('overdue', $result['urgency_level']);
        $this->assertTrue($result['is_overdue']);
        $this->assertFalse($result['is_due_today']);
        $this->assertFalse($result['is_due_soon']);
        $this->assertFalse($result['is_upcoming']);
        $this->assertFalse($result['is_completed']);
        $this->assertStringContainsString('Overdue', $result['remaining_time_human']);
    }

    public function test_exact_time_boundary_is_respected(): void
    {
        // Assignment due at 4:00 PM
        $deadline = Carbon::parse('2026-10-15 16:00:00');
        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Algorithms']);

        $assignment = Assignment::factory()->create([
            'title' => 'Test Assignment',
            'user_id' => $user->id,
            'class_id' => $class->id,
            'status' => AssignmentStatus::Pending,
            'deadline' => $deadline,
        ]);

        // At 3:59 PM: NOT overdue, it is due today
        $before = Carbon::parse('2026-10-15 15:59:00');
        $resultBefore = $this->service->calculate($assignment, $before);
        $this->assertEquals('due_today', $resultBefore['urgency_level']);
        $this->assertFalse($resultBefore['is_overdue']);
        $this->assertTrue($resultBefore['is_due_today']);

        // At 4:00:01 PM: IS overdue
        $after = Carbon::parse('2026-10-15 16:00:01');
        $resultAfter = $this->service->calculate($assignment, $after);
        $this->assertEquals('overdue', $resultAfter['urgency_level']);
        $this->assertTrue($resultAfter['is_overdue']);
        $this->assertFalse($resultAfter['is_due_today']);
    }

    public function test_assignment_due_today_in_the_future(): void
    {
        $frozenNow = Carbon::parse('2026-10-15 09:00:00');
        Carbon::setTestNow($frozenNow);

        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Algorithms']);

        $assignment = Assignment::factory()->create([
            'title' => 'Test Assignment',
            'user_id' => $user->id,
            'class_id' => $class->id,
            'status' => AssignmentStatus::InProgress,
            'deadline' => Carbon::parse('2026-10-15 17:00:00'), // 8 hours left today
        ]);

        $result = $this->service->calculate($assignment, $frozenNow);

        $this->assertEquals('due_today', $result['urgency_level']);
        $this->assertFalse($result['is_overdue']);
        $this->assertTrue($result['is_due_today']);
        $this->assertTrue($result['is_due_soon']);
        $this->assertStringContainsString('Due in', $result['remaining_time_human']);
    }

    public function test_assignment_due_within_48_hours_is_due_soon(): void
    {
        $frozenNow = Carbon::parse('2026-10-15 10:00:00');
        Carbon::setTestNow($frozenNow);

        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Algorithms']);

        $assignment = Assignment::factory()->create([
            'title' => 'Test Assignment',
            'user_id' => $user->id,
            'class_id' => $class->id,
            'status' => AssignmentStatus::Pending,
            'deadline' => Carbon::parse('2026-10-16 18:00:00'), // Tomorrow, within 32 hours
        ]);

        $result = $this->service->calculate($assignment, $frozenNow);

        $this->assertEquals('due_soon', $result['urgency_level']);
        $this->assertFalse($result['is_overdue']);
        $this->assertFalse($result['is_due_today']);
        $this->assertTrue($result['is_due_soon']);
    }

    public function test_assignment_farther_than_48_hours_is_upcoming(): void
    {
        $frozenNow = Carbon::parse('2026-10-15 10:00:00');
        Carbon::setTestNow($frozenNow);

        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Algorithms']);

        $assignment = Assignment::factory()->create([
            'title' => 'Test Assignment',
            'user_id' => $user->id,
            'class_id' => $class->id,
            'status' => AssignmentStatus::Pending,
            'deadline' => Carbon::parse('2026-10-22 10:00:00'), // 7 days later
        ]);

        $result = $this->service->calculate($assignment, $frozenNow);

        $this->assertEquals('upcoming', $result['urgency_level']);
        $this->assertFalse($result['is_overdue']);
        $this->assertFalse($result['is_due_today']);
        $this->assertFalse($result['is_due_soon']);
        $this->assertTrue($result['is_upcoming']);
    }

    public function test_completed_assignment_does_not_appear_overdue_even_if_deadline_passed(): void
    {
        $frozenNow = Carbon::parse('2026-10-20 10:00:00');
        Carbon::setTestNow($frozenNow);

        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Algorithms']);

        $assignment = Assignment::factory()->create([
            'title' => 'Test Assignment',
            'user_id' => $user->id,
            'class_id' => $class->id,
            'status' => AssignmentStatus::Completed,
            'deadline' => Carbon::parse('2026-10-10 10:00:00'), // 10 days ago
            'completed_at' => Carbon::parse('2026-10-09 18:00:00'), // Completed 1 day before deadline
        ]);

        $result = $this->service->calculate($assignment, $frozenNow);

        $this->assertEquals('completed', $result['urgency_level']);
        $this->assertFalse($result['is_overdue']);
        $this->assertTrue($result['is_completed']);
        $this->assertTrue($result['is_completed_on_time']);
        $this->assertEquals('Completed on time', $result['remark']);
    }

    public function test_completed_assignment_records_late_submission_correctly(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create(['user_id' => $user->id, 'course_name' => 'Algorithms']);

        $assignment = Assignment::factory()->create([
            'title' => 'Test Assignment',
            'user_id' => $user->id,
            'class_id' => $class->id,
            'status' => AssignmentStatus::Completed,
            'deadline' => Carbon::parse('2026-10-10 10:00:00'),
            'completed_at' => Carbon::parse('2026-10-11 10:00:00'), // 1 day late
        ]);

        $result = $this->service->calculate($assignment);

        $this->assertEquals('completed', $result['urgency_level']);
        $this->assertFalse($result['is_overdue']);
        $this->assertTrue($result['is_completed']);
        $this->assertFalse($result['is_completed_on_time']);
        $this->assertEquals('Completed after deadline', $result['remark']);
    }
}
