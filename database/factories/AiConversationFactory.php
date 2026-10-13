<?php

namespace Database\Factories;

use App\Models\AiConversation;
use App\Models\Assignment;
use App\Models\CourseClass;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<AiConversation>
 */
class AiConversationFactory extends Factory
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
            'assignment_id' => function (array $attributes) {
                $user = isset($attributes['user_id']) ? User::find($attributes['user_id']) : User::factory()->create();
                $class = CourseClass::factory()->create([
                    'user_id' => $user->id,
                    'course_name' => 'Operating Systems',
                ]);

                return Assignment::factory()->create([
                    'user_id' => $user->id,
                    'class_id' => $class->id,
                    'title' => 'Lab 3: Schedulers',
                    'deadline' => now()->addDays(4),
                ])->id;
            },
            'title' => fake()->sentence(3),
        ];
    }
}
