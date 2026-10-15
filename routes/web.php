<?php

use App\Http\Controllers\Admin\AdminAuthController;
use App\Http\Controllers\Admin\AdminDashboardController;
use App\Http\Controllers\AiChatController;
use App\Http\Controllers\AssignmentAiController;
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

    // Gemini AI Study Assistant (requires premium/genius tier)
    Route::prefix('assignments/{assignment}/ai')->as('assignments.ai.')->middleware('subscription.feature:ai')->group(function () {
        Route::get('messages', [AssignmentAiController::class, 'index'])->name('messages');
        Route::post('chat', [AssignmentAiController::class, 'chat'])->name('chat');
        Route::delete('history', [AssignmentAiController::class, 'clear'])->name('clear');
    });

    // Global Workspace Due Copilot & @Mentions (requires premium/genius tier)
    Route::prefix('ai')->as('ai.')->middleware('subscription.feature:ai')->group(function () {
        Route::get('mentionables', [AiChatController::class, 'mentionables'])->name('mentionables');
        Route::get('messages', [AiChatController::class, 'messages'])->name('messages');
        Route::post('chat', [AiChatController::class, 'chat'])->name('chat');
        Route::delete('history', [AiChatController::class, 'clear'])->name('clear');
    });
});

// Dedicated Admin Portal (Web-only, stealth entrance)
Route::prefix('admin')->group(function () {
    Route::get('login', [AdminAuthController::class, 'showLoginForm'])->name('admin.login');
    Route::post('login', [AdminAuthController::class, 'login'])->name('admin.login.submit');
    Route::post('logout', [AdminAuthController::class, 'logout'])->name('admin.logout');

    Route::middleware(['admin'])->as('admin.')->group(function () {
        Route::get('/', fn () => redirect()->route('admin.dashboard'));
        Route::get('dashboard', [AdminDashboardController::class, 'index'])->name('dashboard');
        Route::get('users', [AdminDashboardController::class, 'users'])->name('users');
        Route::patch('users/{user}/tier', [AdminDashboardController::class, 'updateUserTier'])->name('users.update-tier');
        Route::patch('users/{user}/role', [AdminDashboardController::class, 'updateUserRole'])->name('users.update-role');
        Route::delete('users/{user}/ai', [AdminDashboardController::class, 'clearUserAi'])->name('users.clear-ai');
        Route::get('subscriptions', [AdminDashboardController::class, 'subscriptions'])->name('subscriptions');
        Route::get('storage', [AdminDashboardController::class, 'storage'])->name('storage');
        Route::delete('resources/{resource}', [AdminDashboardController::class, 'deleteResource'])->name('resources.delete');
    });
});

require __DIR__.'/settings.php';
