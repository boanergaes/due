<?php

namespace Database\Factories;

use App\Enums\AssignmentStatus;
use App\Models\Assignment;
use App\Models\CourseClass;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Assignment>
 */
class AssignmentFactory extends Factory
{
    /**
     * The name of the factory's corresponding model.
     *
     * @var class-string<Assignment>
     */
    protected $model = Assignment::class;

    /**
     * Define the model's default state.
     *
     * Only defaults for status, completed_at, and related model associations are set.
     * User-provided values (like title, description, deadline) must be supplied explicitly.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'class_id' => CourseClass::factory(),
            'description' => null,
            'status' => AssignmentStatus::Pending,
            'completed_at' => null,
        ];
    }

    /**
     * Indicate that the assignment is in progress.
     */
    public function inProgress(): static
    {
        return $this->state(fn () => [
            'status' => AssignmentStatus::InProgress,
        ]);
    }

    /**
     * Indicate that the assignment is completed.
     */
    public function completed(): static
    {
        return $this->state(fn () => [
            'status' => AssignmentStatus::Completed,
            'completed_at' => now(),
        ]);
    }

    /**
     * Indicate that the assignment is overdue.
     */
    public function overdue(): static
    {
        return $this->state(fn () => [
            'status' => AssignmentStatus::Pending,
            'deadline' => now()->subDays(2),
            'completed_at' => null,
        ]);
    }

    /**
     * Indicate that the assignment is due today.
     */
    public function dueToday(): static
    {
        return $this->state(fn () => [
            'status' => AssignmentStatus::Pending,
            'deadline' => now()->endOfDay(),
            'completed_at' => null,
        ]);
    }
}
