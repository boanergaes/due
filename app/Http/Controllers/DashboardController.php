<?php

namespace App\Http\Controllers;

use App\Enums\AssignmentStatus;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class DashboardController extends Controller
{
    /**
     * Display the student dashboard with aggregate metrics and upcoming assignments.
     */
    public function index(Request $request): Response
    {
        $user = $request->user();
        $now = now();

        // 1. Numerical counts using database aggregates (no in-memory PHP loops)
        $totalAssignments = $user->assignments()->count();
        $pendingAssignments = $user->assignments()->where('status', AssignmentStatus::Pending)->count();
        $inProgressAssignments = $user->assignments()->where('status', AssignmentStatus::InProgress)->count();
        $completedAssignments = $user->assignments()->where('status', AssignmentStatus::Completed)->count();

        // Overdue assignments: incomplete and deadline is in the past
        $overdueAssignments = $user->assignments()
            ->where('status', '!=', AssignmentStatus::Completed)
            ->where('deadline', '<', $now)
            ->count();

        // Due today assignments: incomplete and deadline is today
        $dueTodayAssignments = $user->assignments()
            ->where('status', '!=', AssignmentStatus::Completed)
            ->whereBetween('deadline', [$now->copy()->startOfDay(), $now->copy()->endOfDay()])
            ->count();

        // 2. Performance metrics with division-by-zero guards
        $completionRate = $totalAssignments > 0
            ? round(($completedAssignments / $totalAssignments) * 100, 1)
            : 0;

        // On-time completion: completed assignments where completion occurred before or on deadline
        $completedOnTime = $user->assignments()
            ->where('status', AssignmentStatus::Completed)
            ->whereNotNull('completed_at')
            ->whereColumn('completed_at', '<=', 'deadline')
            ->count();

        $onTimeCompletionRate = $completedAssignments > 0
            ? round(($completedOnTime / $completedAssignments) * 100, 1)
            : null;

        // Completion velocity: completed in the last 7 days
        $completedRecently = $user->assignments()
            ->where('status', AssignmentStatus::Completed)
            ->where('completed_at', '>=', $now->copy()->subDays(7))
            ->count();

        // 3. Workload by class using withCount to prevent N+1 queries
        $workloadByClass = $user->classes()
            ->withCount([
                'assignments as total_assignments',
                'assignments as active_assignments' => fn ($query) => $query->where('status', '!=', AssignmentStatus::Completed),
                'assignments as completed_assignments' => fn ($query) => $query->where('status', AssignmentStatus::Completed),
            ])
            ->orderByDesc('active_assignments')
            ->orderBy('course_name')
            ->get(['id', 'course_name']);

        // 4. Upcoming assignments (eager loading courseClass prevents N+1 query problem)
        $upcomingAssignments = $user->assignments()
            ->with('courseClass')
            ->where('status', '!=', AssignmentStatus::Completed)
            ->where('deadline', '>=', $now)
            ->orderBy('deadline', 'asc')
            ->take(5)
            ->get();

        // 5. Overdue assignments for immediate alert
        $overdueAssignmentsList = $user->assignments()
            ->with('courseClass')
            ->where('status', '!=', AssignmentStatus::Completed)
            ->where('deadline', '<', $now)
            ->orderBy('deadline', 'asc')
            ->take(5)
            ->get();

        return Inertia::render('dashboard', [
            'metrics' => [
                'total' => $totalAssignments,
                'pending' => $pendingAssignments,
                'in_progress' => $inProgressAssignments,
                'completed' => $completedAssignments,
                'overdue' => $overdueAssignments,
                'due_today' => $dueTodayAssignments,
                'completion_rate' => $completionRate,
                'completed_on_time' => $completedOnTime,
                'on_time_rate' => $onTimeCompletionRate,
                'completed_recently' => $completedRecently,
            ],
            'upcoming_assignments' => $upcomingAssignments,
            'overdue_assignments' => $overdueAssignmentsList,
            'workload_by_class' => $workloadByClass,
        ]);
    }
}
