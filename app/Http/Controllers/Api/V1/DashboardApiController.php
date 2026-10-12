<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\AssignmentStatus;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardApiController extends Controller
{
    /**
     * Return aggregate dashboard metrics and upcoming coursework.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $now = now();

        // 1. Numerical counts using database aggregates
        $totalAssignments = $user->assignments()->count();
        $pendingAssignments = $user->assignments()->where('status', AssignmentStatus::Pending)->count();
        $inProgressAssignments = $user->assignments()->where('status', AssignmentStatus::InProgress)->count();
        $completedAssignments = $user->assignments()->where('status', AssignmentStatus::Completed)->count();

        $overdueAssignments = $user->assignments()
            ->where('status', '!=', AssignmentStatus::Completed)
            ->where('deadline', '<', $now)
            ->count();

        $dueTodayAssignments = $user->assignments()
            ->where('status', '!=', AssignmentStatus::Completed)
            ->whereBetween('deadline', [$now->copy()->startOfDay(), $now->copy()->endOfDay()])
            ->count();

        // 2. Performance metrics
        $completionRate = $totalAssignments > 0
            ? round(($completedAssignments / $totalAssignments) * 100, 1)
            : 0;

        $completedOnTime = $user->assignments()
            ->where('status', AssignmentStatus::Completed)
            ->whereNotNull('completed_at')
            ->whereColumn('completed_at', '<=', 'deadline')
            ->count();

        $onTimeCompletionRate = $completedAssignments > 0
            ? round(($completedOnTime / $completedAssignments) * 100, 1)
            : null;

        $completedRecently = $user->assignments()
            ->where('status', AssignmentStatus::Completed)
            ->where('completed_at', '>=', $now->copy()->subDays(7))
            ->count();

        // 3. Workload by class with eager aggregate counts
        $workloadByClass = $user->classes()
            ->withCount([
                'assignments as total_assignments',
                'assignments as active_assignments' => fn ($query) => $query->where('status', '!=', AssignmentStatus::Completed),
                'assignments as completed_assignments' => fn ($query) => $query->where('status', AssignmentStatus::Completed),
            ])
            ->orderByDesc('active_assignments')
            ->orderBy('course_name')
            ->get(['id', 'course_name', 'credit_hours', 'ects']);

        // 4. Upcoming assignments (eager loaded courseClass, computed urgency)
        $upcomingAssignments = $user->assignments()
            ->with('courseClass')
            ->where('status', '!=', AssignmentStatus::Completed)
            ->where('deadline', '>=', $now)
            ->orderBy('deadline', 'asc')
            ->take(10)
            ->get();

        // 5. Overdue assignments for alerts
        $overdueAssignmentsList = $user->assignments()
            ->with('courseClass')
            ->where('status', '!=', AssignmentStatus::Completed)
            ->where('deadline', '<', $now)
            ->orderBy('deadline', 'asc')
            ->take(10)
            ->get();

        return response()->json([
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
