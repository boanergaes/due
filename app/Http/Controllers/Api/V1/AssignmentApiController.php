<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\AssignmentStatus;
use App\Http\Controllers\Controller;
use App\Http\Requests\Assignments\StoreAssignmentRequest;
use App\Http\Requests\Assignments\UpdateAssignmentRequest;
use App\Http\Requests\Assignments\UpdateAssignmentStatusRequest;
use App\Models\Assignment;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Gate;

class AssignmentApiController extends Controller
{
    /**
     * Display a listing of the user's assignments with filtering, search, and urgency.
     */
    public function index(Request $request): JsonResponse
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

        if ($request->boolean('all')) {
            return response()->json([
                'data' => $query->orderBy('deadline', 'asc')->get(),
            ]);
        }

        $perPage = min($request->integer('per_page', 15), 100);
        $assignments = $query->orderBy('deadline', 'asc')->paginate($perPage);

        return response()->json($assignments);
    }

    /**
     * Store a newly created assignment in storage.
     */
    public function store(StoreAssignmentRequest $request): JsonResponse
    {
        $data = $request->validated();

        if ($data['status'] === AssignmentStatus::Completed->value) {
            $data['completed_at'] = now();
        }

        $assignment = $request->user()->assignments()->create($data);
        $assignment->load('courseClass');

        return response()->json([
            'message' => 'Assignment created successfully',
            'data' => $assignment,
        ], 201);
    }

    /**
     * Display the specified assignment with course class and notes.
     */
    public function show(Assignment $assignment): JsonResponse
    {
        Gate::authorize('view', $assignment);

        $assignment->load([
            'courseClass',
            'notes' => fn ($query) => $query->latest(),
            'resources' => fn ($query) => $query->orderBy('created_at', 'desc'),
        ]);

        return response()->json([
            'data' => $assignment,
        ]);
    }

    /**
     * Update the specified assignment in storage.
     */
    public function update(UpdateAssignmentRequest $request, Assignment $assignment): JsonResponse
    {
        Gate::authorize('update', $assignment);

        $data = $request->validated();

        if ($data['status'] === AssignmentStatus::Completed->value && $assignment->status !== AssignmentStatus::Completed) {
            $data['completed_at'] = now();
        } elseif ($data['status'] !== AssignmentStatus::Completed->value && $assignment->status === AssignmentStatus::Completed) {
            $data['completed_at'] = null;
        }

        $assignment->update($data);
        $assignment->load('courseClass');

        return response()->json([
            'message' => 'Assignment updated successfully',
            'data' => $assignment,
        ]);
    }

    /**
     * Quick update of assignment status.
     */
    public function updateStatus(UpdateAssignmentStatusRequest $request, Assignment $assignment): JsonResponse
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
        $assignment->load('courseClass');

        return response()->json([
            'message' => 'Assignment status updated successfully',
            'data' => $assignment,
        ]);
    }

    /**
     * Remove the specified assignment from storage.
     */
    public function destroy(Assignment $assignment): JsonResponse
    {
        Gate::authorize('delete', $assignment);

        $assignment->delete();

        return response()->json([
            'message' => 'Assignment deleted successfully',
        ]);
    }
}
