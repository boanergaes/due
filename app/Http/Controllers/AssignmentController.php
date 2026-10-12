<?php

namespace App\Http\Controllers;

use App\Enums\AssignmentStatus;
use App\Http\Requests\Assignments\StoreAssignmentRequest;
use App\Http\Requests\Assignments\UpdateAssignmentRequest;
use App\Http\Requests\Assignments\UpdateAssignmentStatusRequest;
use App\Models\Assignment;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Gate;
use Inertia\Inertia;
use Inertia\Response;

class AssignmentController extends Controller
{
    /**
     * Display a listing of the user's assignments with optional filtering, search, and eager loading.
     */
    public function index(Request $request): Response
    {
        $request->validate([
            'search' => ['nullable', 'string', 'max:150'],
            'status' => ['nullable', 'string'],
            'class_id' => ['nullable', 'integer'],
            'start_date' => ['nullable', 'date'],
            'end_date' => ['nullable', 'date', 'after_or_equal:start_date'],
            'urgency' => ['nullable', 'string'],
        ]);

        $query = $request->user()
            ->assignments()
            ->with('courseClass');

        // Text search across title and description
        if ($request->filled('search')) {
            $search = $request->string('search')->trim()->toString();
            $query->where(function ($q) use ($search) {
                $q->where('title', 'like', "%{$search}%")
                    ->orWhere('description', 'like', "%{$search}%");
            });
        }

        // Status filter
        if ($request->filled('status')) {
            $query->where('status', $request->string('status')->toString());
        }

        // Class filter
        if ($request->filled('class_id')) {
            $query->where('class_id', $request->integer('class_id'));
        }

        // Date range filters
        if ($request->filled('start_date')) {
            $query->where('deadline', '>=', Carbon::parse($request->input('start_date'))->startOfDay());
        }

        if ($request->filled('end_date')) {
            $query->where('deadline', '<=', Carbon::parse($request->input('end_date'))->endOfDay());
        }

        // Urgency preset filter
        if ($request->filled('urgency')) {
            $now = now();
            match ($request->string('urgency')->toString()) {
                'overdue' => $query->where('status', '!=', AssignmentStatus::Completed)
                    ->where('deadline', '<', $now),
                'due_today' => $query->where('status', '!=', AssignmentStatus::Completed)
                    ->whereBetween('deadline', [$now->copy()->startOfDay(), $now->copy()->endOfDay()]),
                'due_soon' => $query->where('status', '!=', AssignmentStatus::Completed)
                    ->whereBetween('deadline', [$now, $now->copy()->addHours(48)]),
                'upcoming' => $query->where('status', '!=', AssignmentStatus::Completed)
                    ->where('deadline', '>=', $now),
                default => null,
            };
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
                'search' => $request->string('search')->toString() ?: null,
                'status' => $request->string('status')->toString() ?: null,
                'class_id' => $request->string('class_id')->toString() ?: null,
                'start_date' => $request->string('start_date')->toString() ?: null,
                'end_date' => $request->string('end_date')->toString() ?: null,
                'urgency' => $request->string('urgency')->toString() ?: null,
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

        $assignment->load([
            'courseClass',
            'notes' => fn ($query) => $query->latest(),
        ]);

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
