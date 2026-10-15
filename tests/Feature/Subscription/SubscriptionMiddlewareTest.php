<?php

use App\Enums\SubscriptionTier;
use App\Models\User;
use App\Services\SubscriptionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;

uses(RefreshDatabase::class);

beforeEach(function () {
    Route::middleware(['web', 'auth', 'subscription.feature:resources'])->get('/test-resources-feature', function () {
        return response('resources_ok');
    });

    Route::middleware(['web', 'auth', 'subscription.feature:ai'])->get('/test-ai-feature', function () {
        return response('ai_ok');
    });

    Route::middleware(['auth:sanctum', 'subscription.feature:resources'])->get('/api/test-resources', function () {
        return response()->json(['status' => 'resources_ok']);
    });

    Route::middleware(['auth:sanctum', 'subscription.feature:ai'])->get('/api/test-ai', function () {
        return response()->json(['status' => 'ai_ok']);
    });
});

test('free tier is blocked from resources and ai features on web', function () {
    $user = User::factory()->create([
        'subscription_tier' => SubscriptionTier::Free,
    ]);

    $this->actingAs($user)
        ->get('/test-resources-feature')
        ->assertRedirect(route('pricing'));

    $this->actingAs($user)
        ->get('/test-ai-feature')
        ->assertRedirect(route('pricing'));
});

test('scholar tier can access resources feature but is blocked from ai feature on web', function () {
    $user = User::factory()->scholar()->create();

    $this->actingAs($user)
        ->get('/test-resources-feature')
        ->assertOk()
        ->assertSee('resources_ok');

    $this->actingAs($user)
        ->get('/test-ai-feature')
        ->assertRedirect(route('pricing'));
});

test('genius tier can access both resources and ai features on web', function () {
    $user = User::factory()->genius()->create();

    $this->actingAs($user)
        ->get('/test-resources-feature')
        ->assertOk()
        ->assertSee('resources_ok');

    $this->actingAs($user)
        ->get('/test-ai-feature')
        ->assertOk()
        ->assertSee('ai_ok');
});

test('admin can access all features regardless of tier on web', function () {
    $admin = User::factory()->admin()->create([
        'subscription_tier' => SubscriptionTier::Free,
    ]);

    $this->actingAs($admin)
        ->get('/test-resources-feature')
        ->assertOk()
        ->assertSee('resources_ok');

    $this->actingAs($admin)
        ->get('/test-ai-feature')
        ->assertOk()
        ->assertSee('ai_ok');
});

test('feature gate performs zero database queries to subscriptions table when passport is in session', function () {
    $user = User::factory()->scholar()->create();

    // Prime the session passport
    $service = app(SubscriptionService::class);
    $passport = $service->generatePassport($user);

    DB::flushQueryLog();
    DB::enableQueryLog();

    $this->actingAs($user)
        ->withSession(['subscription_passport' => $passport])
        ->get('/test-resources-feature')
        ->assertOk();

    $queries = DB::getQueryLog();
    $subscriptionQueries = array_filter($queries, function ($q) {
        return str_contains(strtolower($q['query']), 'subscriptions');
    });

    // Zero queries to the subscriptions table!
    expect($subscriptionQueries)->toBeEmpty();
});
