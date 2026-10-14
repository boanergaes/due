<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Classes\StoreCourseClassRequest;
use App\Http\Requests\Classes\UpdateCourseClassRequest;
use App\Models\CourseClass;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class CourseClassApiController extends Controller
{
    /**
     * Display a listing of the user's classes.
     */
    public function index(Request $request): JsonResponse
    {
        $query = $request->user()
            ->classes()
            ->withCount('assignments')
            ->orderBy('course_name');

        if ($request->boolean('all')) {
            return response()->json([
                'data' => $query->get(),
            ]);
        }

        $perPage = min($request->integer('per_page', 15), 100);
        $classes = $query->paginate($perPage);

        return response()->json($classes);
    }

    /**
     * Store a newly created class in storage.
     */
    public function store(StoreCourseClassRequest $request): JsonResponse
    {
        $courseClass = $request->user()->classes()->create($request->validated());
        $courseClass->loadCount('assignments');

        return response()->json([
            'message' => 'Class created successfully',
            'data' => $courseClass,
        ], 201);
    }

    /**
     * Display the specified class with its assignments.
     */
    public function show(CourseClass $courseClass): JsonResponse
    {
        Gate::authorize('view', $courseClass);

        $courseClass->loadCount('assignments');
        $courseClass->load([
            'assignments' => fn ($query) => $query->orderBy('deadline'),
            'resources' => fn ($query) => $query->orderBy('created_at', 'desc'),
        ]);

        return response()->json([
            'data' => $courseClass,
        ]);
    }

    /**
     * Update the specified class in storage.
     */
    public function update(UpdateCourseClassRequest $request, CourseClass $courseClass): JsonResponse
    {
        Gate::authorize('update', $courseClass);

        $courseClass->update($request->validated());
        $courseClass->loadCount('assignments');

        return response()->json([
            'message' => 'Class updated successfully',
            'data' => $courseClass,
        ]);
    }

    /**
     * Remove the specified class from storage.
     */
    public function destroy(CourseClass $courseClass): JsonResponse
    {
        Gate::authorize('delete', $courseClass);

        if ($courseClass->assignments()->exists()) {
            return response()->json([
                'message' => 'Cannot delete course "'.$courseClass->course_name.'" because it has assignments associated with it. Please reassign or delete the assignments first.',
            ], 422);
        }

        $courseClass->delete();

        return response()->json([
            'message' => 'Class deleted successfully',
        ]);
    }
}
