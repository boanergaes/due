<?php

namespace App\Policies;

use App\Models\CourseClass;
use App\Models\User;

class CourseClassPolicy
{
    /**
     * Determine whether the user can view any course classes.
     */
    public function viewAny(User $user): bool
    {
        return true;
    }

    /**
     * Determine whether the user can view the course class.
     */
    public function view(User $user, CourseClass $courseClass): bool
    {
        return $user->id === $courseClass->user_id;
    }

    /**
     * Determine whether the user can create course classes.
     */
    public function create(User $user): bool
    {
        return true;
    }

    /**
     * Determine whether the user can update the course class.
     */
    public function update(User $user, CourseClass $courseClass): bool
    {
        return $user->id === $courseClass->user_id;
    }

    /**
     * Determine whether the user can delete the course class.
     */
    public function delete(User $user, CourseClass $courseClass): bool
    {
        return $user->id === $courseClass->user_id;
    }
}
