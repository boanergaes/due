<?php

namespace Database\Factories;

use App\Models\Assignment;
use App\Models\AssignmentNote;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<AssignmentNote>
 */
class AssignmentNoteFactory extends Factory
{
    /**
     * The name of the factory's corresponding model.
     *
     * @var class-string<AssignmentNote>
     */
    protected $model = AssignmentNote::class;

    /**
     * Define the model's default state.
     *
     * Only related model associations are set. Content must be supplied explicitly.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'assignment_id' => Assignment::factory(),
        ];
    }
}
