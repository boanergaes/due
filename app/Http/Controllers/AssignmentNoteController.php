<?php

namespace App\Http\Controllers;

use App\Http\Requests\Notes\StoreAssignmentNoteRequest;
use App\Http\Requests\Notes\UpdateAssignmentNoteRequest;
use App\Models\Assignment;
use App\Models\AssignmentNote;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class AssignmentNoteController extends Controller
{
    /**
     * Store a newly created note for an assignment.
     */
    public function store(StoreAssignmentNoteRequest $request, Assignment $assignment): RedirectResponse
    {
        $assignment->notes()->create($request->validated());

        return back()->with('success', 'Note added successfully.');
    }

    /**
     * Update the specified note.
     */
    public function update(UpdateAssignmentNoteRequest $request, Assignment $assignment, AssignmentNote $note): RedirectResponse
    {
        abort_unless($note->assignment_id === $assignment->id, 404);

        $note->update($request->validated());

        return back()->with('success', 'Note updated successfully.');
    }

    /**
     * Remove the specified note.
     */
    public function destroy(Request $request, Assignment $assignment, AssignmentNote $note): RedirectResponse
    {
        abort_unless($note->assignment_id === $assignment->id, 404);

        Gate::authorize('delete', $note);

        $note->delete();

        return back()->with('success', 'Note deleted successfully.');
    }
}
