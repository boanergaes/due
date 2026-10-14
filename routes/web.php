<?php

use App\Http\Controllers\AssignmentController;
use App\Http\Controllers\AssignmentNoteController;
use App\Http\Controllers\CourseClassController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\ResourceController;
use App\Http\Controllers\SubscriptionController;
use Illuminate\Support\Facades\Route;

Route::inertia('/', 'welcome')->name('home');
Route::get('pricing', [SubscriptionController::class, 'pricing'])->name('pricing');

Route::middleware(['auth'])->group(function () {
    Route::get('dashboard', [DashboardController::class, 'index'])->name('dashboard');

    Route::get('checkout', [SubscriptionController::class, 'checkout'])->name('checkout');
    Route::post('checkout', [SubscriptionController::class, 'processCheckout'])->name('checkout.process');
    Route::get('settings/subscription', [SubscriptionController::class, 'settings'])->name('subscription.settings');
    Route::post('settings/subscription/cancel', [SubscriptionController::class, 'cancel'])->name('subscription.cancel');

    Route::resource('classes', CourseClassController::class)->parameters([
        'classes' => 'courseClass',
    ]);

    Route::patch('assignments/{assignment}/status', [AssignmentController::class, 'updateStatus'])
        ->name('assignments.update-status');
    Route::resource('assignments', AssignmentController::class);

    Route::post('assignments/{assignment}/notes', [AssignmentNoteController::class, 'store'])
        ->name('assignments.notes.store');
    Route::put('assignments/{assignment}/notes/{note}', [AssignmentNoteController::class, 'update'])
        ->name('assignments.notes.update');
    Route::delete('assignments/{assignment}/notes/{note}', [AssignmentNoteController::class, 'destroy'])
        ->name('assignments.notes.destroy');

    // Study resources (upload requires basic/scholar tier or higher)
    Route::post('resources/upload', [ResourceController::class, 'store'])
        ->middleware('subscription.feature:resources')
        ->name('resources.upload');
    Route::get('resources/{resource}/view', [ResourceController::class, 'view'])
        ->name('resources.view');
    Route::get('resources/{resource}/download', [ResourceController::class, 'download'])
        ->name('resources.download');
    Route::delete('resources/{resource}', [ResourceController::class, 'destroy'])
        ->name('resources.destroy');
});

require __DIR__.'/settings.php';
