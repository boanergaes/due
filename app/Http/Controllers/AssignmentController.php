<?php

namespace App\Http\Controllers;

use App\Enums\AssignmentStatus;
use App\Http\Requests\Assignments\StoreAssignmentRequest;
use App\Http\Requests\Assignments\UpdateAssignmentRequest;
use App\Http\Requests\Assignments\UpdateAssignmentStatusRequest;
use App\Models\Assignment;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Inertia\Inertia;
use Inertia\Response;

class AssignmentController extends Controller
{
    /**
     * Display a listing of the user's assignments with optional filtering and eager loading.
     */
    public function index(Request $request): Response
    {
        $query = $request->user()
            ->assignments()
            ->with('courseClass');

        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        }

        if ($request->filled('class_id')) {
            $query->where('class_id', $request->integer('class_id'));
        }

        $assignments = $query->orderBy('deadline', 'asc')
            ->paginate(10)
            ->withQueryString();

        $classes = $request->user()
            ->classes()
            ->orderBy('course_name')
            ->get(['id', 'course_name']);

        return Inertia::render('assignments/index', [
            'assignments' => $assignments,
            'classes' => $classes,
            'filters' => [
                'status' => $request->string('status')->toString() ?: null,
                'class_id' => $request->string('class_id')->toString() ?: null,
            ],
        ]);
    }

    /**
     * Show the form for creating a new assignment.
     */
    public function create(Request $request): Response
    {
        $classes = $request->user()
            ->classes()
            ->orderBy('course_name')
            ->get(['id', 'course_name']);

        return Inertia::render('assignments/create', [
            'classes' => $classes,
        ]);
    }

    /**
     * Store a newly created assignment in storage.
     */
    public function store(StoreAssignmentRequest $request): RedirectResponse
    {
        $data = $request->validated();

        if ($data['status'] === AssignmentStatus::Completed->value) {
            $data['completed_at'] = now();
        }

        $request->user()->assignments()->create($data);

        return redirect()->route('assignments.index')->with('success', 'Assignment created successfully.');
    }

    /**
     * Display the specified assignment.
     */
    public function show(Assignment $assignment): Response
    {
        Gate::authorize('view', $assignment);

        $assignment->load('courseClass');

        return Inertia::render('assignments/show', [
            'assignment' => $assignment,
        ]);
    }

    /**
     * Show the form for editing the specified assignment.
     */
    public function edit(Assignment $assignment, Request $request): Response
    {
        Gate::authorize('update', $assignment);

        $classes = $request->user()
            ->classes()
            ->orderBy('course_name')
            ->get(['id', 'course_name']);

        return Inertia::render('assignments/edit', [
            'assignment' => $assignment,
            'classes' => $classes,
        ]);
    }

    /**
     * Update the specified assignment in storage.
     */
    public function update(UpdateAssignmentRequest $request, Assignment $assignment): RedirectResponse
    {
        Gate::authorize('update', $assignment);

        $data = $request->validated();

        if ($data['status'] === AssignmentStatus::Completed->value && $assignment->status !== AssignmentStatus::Completed) {
            $data['completed_at'] = now();
        } elseif ($data['status'] !== AssignmentStatus::Completed->value && $assignment->status === AssignmentStatus::Completed) {
            $data['completed_at'] = null;
        }

        $assignment->update($data);

        return redirect()->route('assignments.index')->with('success', 'Assignment updated successfully.');
    }

    /**
     * Quick update of assignment status.
     */
    public function updateStatus(UpdateAssignmentStatusRequest $request, Assignment $assignment): RedirectResponse
    {
        Gate::authorize('update', $assignment);

        $newStatus = AssignmentStatus::from($request->validated('status'));

        if ($newStatus === AssignmentStatus::Completed && $assignment->status !== AssignmentStatus::Completed) {
            $assignment->completed_at = now();
        } elseif ($newStatus !== AssignmentStatus::Completed && $assignment->status === AssignmentStatus::Completed) {
            $assignment->completed_at = null;
        }

        $assignment->status = $newStatus;
        $assignment->save();

        return back()->with('success', 'Status updated.');
    }

    /**
     * Remove the specified assignment from storage.
     */
    public function destroy(Assignment $assignment): RedirectResponse
    {
        Gate::authorize('delete', $assignment);

        $assignment->delete();

        return redirect()->route('assignments.index')->with('success', 'Assignment deleted successfully.');
    }
}
