<?php

namespace Database\Factories;

use App\Models\CourseClass;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<CourseClass>
 */
class CourseClassFactory extends Factory
{
    /**
     * The name of the factory's corresponding model.
     *
     * @var class-string<CourseClass>
     */
    protected $model = CourseClass::class;

    /**
     * Define the model's default state.
     *
     * Only related fields and optional nullable defaults are specified here.
     * User-provided values (like course_name, teacher, credits) must be supplied explicitly.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'teacher_name' => null,
            'teacher_contact' => null,
            'credit_hours' => null,
            'ects' => null,
        ];
    }
}
