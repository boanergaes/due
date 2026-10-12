<?php

namespace App\Policies;

use App\Models\Assignment;
use App\Models\AssignmentNote;
use App\Models\User;

class AssignmentNotePolicy
{
    /**
     * Determine whether the user can create a note on the assignment.
     */
    public function create(User $user, Assignment $assignment): bool
    {
        return $user->id === $assignment->user_id;
    }

    /**
     * Determine whether the user can update the note.
     */
    public function update(User $user, AssignmentNote $note): bool
    {
        return $user->id === $note->assignment->user_id;
    }

    /**
     * Determine whether the user can delete the note.
     */
    public function delete(User $user, AssignmentNote $note): bool
    {
        return $user->id === $note->assignment->user_id;
    }
}
