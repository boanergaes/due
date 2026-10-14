<?php

namespace App\Http\Controllers;

use App\Http\Requests\Classes\StoreCourseClassRequest;
use App\Http\Requests\Classes\UpdateCourseClassRequest;
use App\Models\CourseClass;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Inertia\Inertia;
use Inertia\Response;

class CourseClassController extends Controller
{
    /**
     * Display a listing of the user's classes.
     */
    public function index(Request $request): Response
    {
        $classes = $request->user()
            ->classes()
            ->withCount('assignments')
            ->orderBy('course_name')
            ->paginate(10);

        return Inertia::render('classes/index', [
            'classes' => $classes,
        ]);
    }

    /**
     * Show the form for creating a new class.
     */
    public function create(): Response
    {
        return Inertia::render('classes/create');
    }

    /**
     * Store a newly created class in storage.
     */
    public function store(StoreCourseClassRequest $request): RedirectResponse
    {
        $request->user()->classes()->create($request->validated());

        return redirect()->route('classes.index')->with('success', 'Class created successfully.');
    }

    /**
     * Display the specified class with its assignments.
     */
    public function show(CourseClass $courseClass): Response
    {
        Gate::authorize('view', $courseClass);

        $courseClass->load([
            'assignments' => fn ($query) => $query->orderBy('deadline'),
            'resources' => fn ($query) => $query->orderBy('created_at', 'desc'),
        ]);

        return Inertia::render('classes/show', [
            'courseClass' => $courseClass,
        ]);
    }

    /**
     * Show the form for editing the specified class.
     */
    public function edit(CourseClass $courseClass): Response
    {
        Gate::authorize('update', $courseClass);

        return Inertia::render('classes/edit', [
            'courseClass' => $courseClass,
        ]);
    }

    /**
     * Update the specified class in storage.
     */
    public function update(UpdateCourseClassRequest $request, CourseClass $courseClass): RedirectResponse
    {
        Gate::authorize('update', $courseClass);

        $courseClass->update($request->validated());

        return redirect()->route('classes.index')->with('success', 'Class updated successfully.');
    }

    /**
     * Remove the specified class from storage.
     */
    public function destroy(CourseClass $courseClass): RedirectResponse
    {
        Gate::authorize('delete', $courseClass);

        if ($courseClass->assignments()->exists()) {
            return back()->withErrors([
                'delete' => 'Cannot delete course "'.$courseClass->course_name.'" because it has assignments associated with it. Please reassign or delete the assignments first.',
            ]);
        }

        $courseClass->delete();

        return redirect()->route('classes.index')->with('success', 'Class deleted successfully.');
    }
}
