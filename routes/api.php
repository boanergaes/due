<?php

use App\Http\Controllers\Api\V1\AssignmentApiController;
use App\Http\Controllers\Api\V1\AssignmentNoteApiController;
use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\CourseClassApiController;
use App\Http\Controllers\Api\V1\DashboardApiController;
use App\Http\Controllers\Api\V1\ResourceApiController;
use App\Http\Controllers\Api\V1\SubscriptionApiController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->as('api.v1.')->group(function () {
    // Guest Authentication
    Route::post('auth/login', [AuthController::class, 'login']);
    Route::post('auth/register', [AuthController::class, 'register']);

    // Authenticated Mobile Endpoints
    Route::middleware('auth:sanctum')->group(function () {
        // User Profile, Preferences & Logout
        Route::get('auth/user', [AuthController::class, 'user']);
        Route::post('auth/logout', [AuthController::class, 'logout']);
        Route::patch('auth/appearance', [AuthController::class, 'updateAppearance']);

        // Subscription, Abilities & Quota
        Route::get('subscription', [SubscriptionApiController::class, 'index']);
        Route::post('subscription/checkout', [SubscriptionApiController::class, 'checkout']);
        Route::post('subscription/cancel', [SubscriptionApiController::class, 'cancel']);

        // Dashboard Metrics & Upcoming Feed
        Route::get('dashboard', [DashboardApiController::class, 'index']);

        // Academic Course Classes CRUD
        Route::apiResource('classes', CourseClassApiController::class)->parameters([
            'classes' => 'courseClass',
        ]);

        // Coursework Assignments CRUD & Quick Status Toggle
        Route::patch('assignments/{assignment}/status', [AssignmentApiController::class, 'updateStatus']);
        Route::apiResource('assignments', AssignmentApiController::class);

        // Assignment Notes CRUD
        Route::get('assignments/{assignment}/notes', [AssignmentNoteApiController::class, 'index']);
        Route::post('assignments/{assignment}/notes', [AssignmentNoteApiController::class, 'store']);
        Route::put('assignments/{assignment}/notes/{note}', [AssignmentNoteApiController::class, 'update']);
        Route::delete('assignments/{assignment}/notes/{note}', [AssignmentNoteApiController::class, 'destroy']);

        // Study Resources (Mobile API)
        Route::get('resources', [ResourceApiController::class, 'index']);
        Route::post('resources', [ResourceApiController::class, 'store'])
            ->middleware('subscription.feature:resources');
        Route::get('resources/{resource}', [ResourceApiController::class, 'show']);
        Route::get('resources/{resource}/view', [ResourceApiController::class, 'view']);
        Route::get('resources/{resource}/download', [ResourceApiController::class, 'download']);
        Route::delete('resources/{resource}', [ResourceApiController::class, 'destroy']);
    });
});
