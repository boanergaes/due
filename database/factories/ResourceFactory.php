<?php

namespace Database\Factories;

use App\Models\Assignment;
use App\Models\CourseClass;
use App\Models\Resource;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<resource>
 */
class ResourceFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'resourceable_type' => Assignment::class,
            'resourceable_id' => function (array $attributes) {
                $user = isset($attributes['user_id']) ? User::find($attributes['user_id']) : User::factory()->create();
                $class = CourseClass::factory()->create([
                    'user_id' => $user->id,
                    'course_name' => 'Computer Science 101',
                ]);

                return Assignment::factory()->create([
                    'user_id' => $user->id,
                    'class_id' => $class->id,
                    'title' => fake()->sentence(3),
                    'deadline' => now()->addDays(5),
                ])->id;
            },
            'title' => fake()->sentence(3),
            'file_name' => fake()->word().'.pdf',
            'file_path' => 'resources/mock/'.fake()->uuid().'.pdf',
            'mime_type' => 'application/pdf',
            'file_size_bytes' => fake()->numberBetween(1024 * 100, 1024 * 1024 * 5),
            'extracted_text' => fake()->paragraphs(3, true),
        ];
    }

    /**
     * Indicate that the resource is an image.
     */
    public function image(): static
    {
        return $this->state(fn (array $attributes) => [
            'file_name' => fake()->word().'.png',
            'file_path' => 'resources/mock/'.fake()->uuid().'.png',
            'mime_type' => 'image/png',
            'extracted_text' => null,
        ]);
    }

    /**
     * Indicate that the resource is attached to a CourseClass.
     */
    public function forClass(CourseClass $class): static
    {
        return $this->state(fn (array $attributes) => [
            'user_id' => $class->user_id,
            'resourceable_type' => CourseClass::class,
            'resourceable_id' => $class->id,
        ]);
    }

    /**
     * Indicate that the resource is attached to an Assignment.
     */
    public function forAssignment(Assignment $assignment): static
    {
        return $this->state(fn (array $attributes) => [
            'user_id' => $assignment->user_id,
            'resourceable_type' => Assignment::class,
            'resourceable_id' => $assignment->id,
        ]);
    }
}
