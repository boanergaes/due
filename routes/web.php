<?php

use App\Http\Controllers\AssignmentController;
use App\Http\Controllers\CourseClassController;
use Illuminate\Support\Facades\Route;

Route::inertia('/', 'welcome')->name('home');

Route::middleware(['auth'])->group(function () {
    Route::inertia('dashboard', 'dashboard')->name('dashboard');

    Route::resource('classes', CourseClassController::class)->parameters([
        'classes' => 'courseClass',
    ]);

    Route::patch('assignments/{assignment}/status', [AssignmentController::class, 'updateStatus'])
        ->name('assignments.update-status');
    Route::resource('assignments', AssignmentController::class);
});

require __DIR__.'/settings.php';
