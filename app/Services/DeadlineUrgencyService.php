<?php

namespace App\Services;

use App\Enums\AssignmentStatus;
use App\Models\Assignment;
use Carbon\CarbonInterface;
use Illuminate\Support\Carbon;

class DeadlineUrgencyService
{
    /**
     * Threshold in hours to consider an incomplete assignment "Due Soon" (default 48 hours).
     */
    public const DUE_SOON_HOURS = 48;

    /**
     * Calculate comprehensive deadline urgency metrics for a given assignment.
     *
     * @param  Assignment  $assignment
     * @param  CarbonInterface|null  $now  Optional clock instance for deterministic testing.
     * @return array<string, mixed>
     */
    public function calculate(Assignment $assignment, ?CarbonInterface $now = null): array
    {
        $currentTime = $now ? Carbon::instance($now) : Carbon::now();
        $deadline = Carbon::instance($assignment->deadline);
        $isCompleted = $assignment->status === AssignmentStatus::Completed;

        if ($isCompleted) {
            $completedAt = $assignment->completed_at ? Carbon::instance($assignment->completed_at) : null;
            $completedOnTime = $completedAt ? $completedAt->lte($deadline) : null;

            $remark = match ($completedOnTime) {
                true => 'Completed on time',
                false => 'Completed after deadline',
                default => 'Completed',
            };

            return [
                'urgency_level' => 'completed',
                'label' => 'Completed',
                'badge_color' => 'emerald',
                'remaining_time_human' => 'Completed',
                'remark' => $remark,
                'hours_remaining' => null,
                'is_overdue' => false,
                'is_due_today' => false,
                'is_due_soon' => false,
                'is_upcoming' => false,
                'is_completed' => true,
                'is_completed_on_time' => $completedOnTime,
            ];
        }

        // Incomplete assignments:
        // 1. Overdue: exact deadline timestamp has passed
        if ($currentTime->gt($deadline)) {
            $diffHuman = $currentTime->diffForHumans($deadline, [
                'parts' => 1,
                'syntax' => CarbonInterface::DIFF_ABSOLUTE,
            ]);

            $minutesLate = $currentTime->diffInMinutes($deadline);
            $hoursRemaining = -1 * round($minutesLate / 60, 1);

            return [
                'urgency_level' => 'overdue',
                'label' => 'Overdue',
                'badge_color' => 'red',
                'remaining_time_human' => "Overdue by {$diffHuman}",
                'remark' => 'Critical: submission deadline has passed.',
                'hours_remaining' => $hoursRemaining,
                'is_overdue' => true,
                'is_due_today' => false,
                'is_due_soon' => false,
                'is_upcoming' => false,
                'is_completed' => false,
                'is_completed_on_time' => null,
            ];
        }

        // 2. Due Today: deadline is today on current calendar date and in the future
        if ($deadline->isSameDay($currentTime)) {
            $diffHuman = $currentTime->diffForHumans($deadline, [
                'parts' => 1,
                'syntax' => CarbonInterface::DIFF_ABSOLUTE,
            ]);

            $minutesLeft = $currentTime->diffInMinutes($deadline);
            $hoursRemaining = round($minutesLeft / 60, 1);

            return [
                'urgency_level' => 'due_today',
                'label' => 'Due Today',
                'badge_color' => 'amber',
                'remaining_time_human' => "Due in {$diffHuman}",
                'remark' => 'Immediate attention required: cutoff is today.',
                'hours_remaining' => $hoursRemaining,
                'is_overdue' => false,
                'is_due_today' => true,
                'is_due_soon' => true,
                'is_upcoming' => false,
                'is_completed' => false,
                'is_completed_on_time' => null,
            ];
        }

        // 3. Due Soon: deadline is within the next 48 hours
        $hoursLeft = $currentTime->diffInHours($deadline, false);
        if ($hoursLeft <= self::DUE_SOON_HOURS) {
            $diffHuman = $currentTime->diffForHumans($deadline, [
                'parts' => 1,
                'syntax' => CarbonInterface::DIFF_ABSOLUTE,
            ]);

            return [
                'urgency_level' => 'due_soon',
                'label' => 'Due Soon',
                'badge_color' => 'amber',
                'remaining_time_human' => "Due in {$diffHuman}",
                'remark' => 'Approaching deadline: prioritize this task soon.',
                'hours_remaining' => round($currentTime->diffInMinutes($deadline) / 60, 1),
                'is_overdue' => false,
                'is_due_today' => false,
                'is_due_soon' => true,
                'is_upcoming' => false,
                'is_completed' => false,
                'is_completed_on_time' => null,
            ];
        }

        // 4. Upcoming: deadline is sufficiently far away
        $diffHuman = $currentTime->diffForHumans($deadline, [
            'parts' => 1,
            'syntax' => CarbonInterface::DIFF_ABSOLUTE,
        ]);

        return [
            'urgency_level' => 'upcoming',
            'label' => 'Upcoming',
            'badge_color' => 'blue',
            'remaining_time_human' => "Due in {$diffHuman}",
            'remark' => 'On schedule: plan ahead for upcoming delivery.',
            'hours_remaining' => round($currentTime->diffInMinutes($deadline) / 60, 1),
            'is_overdue' => false,
            'is_due_today' => false,
            'is_due_soon' => false,
            'is_upcoming' => true,
            'is_completed' => false,
            'is_completed_on_time' => null,
        ];
    }
}
