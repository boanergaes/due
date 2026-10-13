<?php

use App\Enums\SubscriptionTier;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Route;
use Laravel\Sanctum\Sanctum;

uses(RefreshDatabase::class);

beforeEach(function () {
    Route::middleware(['auth:sanctum', 'subscription.feature:resources'])->get('/api/v1/test-resources-gate', function () {
        return response()->json(['status' => 'resources_allowed']);
    });

    Route::middleware(['auth:sanctum', 'subscription.feature:ai'])->get('/api/v1/test-ai-gate', function () {
        return response()->json(['status' => 'ai_allowed']);
    });
});

test('api subscription index returns status and abilities', function () {
    $user = User::factory()->scholar()->create();
    Sanctum::actingAs($user, ['feature:core', 'feature:resources']);

    $response = $this->getJson('/api/v1/subscription');

    $response->assertOk()
        ->assertJson([
            'tier' => 'basic',
            'tier_label' => 'Scholar',
            'is_super_admin' => false,
            'abilities' => ['feature:core', 'feature:resources'],
        ]);
});

test('api mock checkout upgrades user and returns updated abilities', function () {
    $user = User::factory()->create([
        'subscription_tier' => SubscriptionTier::Free,
    ]);
    Sanctum::actingAs($user, ['feature:core']);

    $response = $this->postJson('/api/v1/subscription/checkout', [
        'tier' => 'premium',
        'interval' => 'monthly',
        'cardholder_name' => 'Bob Mobile',
        'card_number' => '4242 4242 4242 4242',
        'exp_month' => '11',
        'exp_year' => '29',
        'cvc' => '999',
        'postal_code' => '10001',
    ]);

    $response->assertOk()
        ->assertJson([
            'tier' => 'premium',
            'tier_label' => 'Genius',
            'abilities' => ['feature:core', 'feature:resources', 'feature:ai'],
        ]);

    $user->refresh();
    expect($user->subscription_tier)->toBe(SubscriptionTier::Premium);
    expect($user->activeSubscription)->not->toBeNull();
    expect($user->activeSubscription->tier)->toBe(SubscriptionTier::Premium);
});

test('api subscription cancel returns account to free tier', function () {
    $user = User::factory()->genius()->create();
    Sanctum::actingAs($user, ['feature:core', 'feature:resources', 'feature:ai']);

    $response = $this->postJson('/api/v1/subscription/cancel');

    $response->assertOk()
        ->assertJson([
            'tier' => 'free',
            'abilities' => ['feature:core'],
        ]);

    $user->refresh();
    expect($user->subscription_tier)->toBe(SubscriptionTier::Free);
});

test('api feature gate denies free tier and allows genius tier via sanctum abilities', function () {
    $freeUser = User::factory()->create(['subscription_tier' => SubscriptionTier::Free]);
    Sanctum::actingAs($freeUser, ['feature:core']);

    $this->getJson('/api/v1/test-resources-gate')
        ->assertStatus(403)
        ->assertJson(['error' => 'Subscription upgrade required']);

    $this->getJson('/api/v1/test-ai-gate')
        ->assertStatus(403)
        ->assertJson(['error' => 'Subscription upgrade required']);

    $geniusUser = User::factory()->genius()->create();
    Sanctum::actingAs($geniusUser, ['feature:core', 'feature:resources', 'feature:ai']);

    $this->getJson('/api/v1/test-resources-gate')
        ->assertOk()
        ->assertJson(['status' => 'resources_allowed']);

    $this->getJson('/api/v1/test-ai-gate')
        ->assertOk()
        ->assertJson(['status' => 'ai_allowed']);
});
