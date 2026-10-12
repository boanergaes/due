<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Notes\StoreAssignmentNoteRequest;
use App\Http\Requests\Notes\UpdateAssignmentNoteRequest;
use App\Models\Assignment;
use App\Models\AssignmentNote;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class AssignmentNoteApiController extends Controller
{
    /**
     * Display a listing of notes for the specified assignment.
     */
    public function index(Assignment $assignment): JsonResponse
    {
        Gate::authorize('view', $assignment);

        $notes = $assignment->notes()->latest()->get();

        return response()->json([
            'data' => $notes,
        ]);
    }

    /**
     * Store a newly created note for the specified assignment.
     */
    public function store(StoreAssignmentNoteRequest $request, Assignment $assignment): JsonResponse
    {
        $note = $assignment->notes()->create($request->validated());

        return response()->json([
            'message' => 'Note created successfully',
            'data' => $note,
        ], 201);
    }

    /**
     * Update the specified note.
     */
    public function update(UpdateAssignmentNoteRequest $request, Assignment $assignment, AssignmentNote $note): JsonResponse
    {
        abort_unless($note->assignment_id === $assignment->id, 404);

        $note->update($request->validated());

        return response()->json([
            'message' => 'Note updated successfully',
            'data' => $note,
        ]);
    }

    /**
     * Remove the specified note.
     */
    public function destroy(Request $request, Assignment $assignment, AssignmentNote $note): JsonResponse
    {
        abort_unless($note->assignment_id === $assignment->id, 404);

        Gate::authorize('delete', $note);

        $note->delete();

        return response()->json([
            'message' => 'Note deleted successfully',
        ]);
    }
}
