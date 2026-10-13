<?php

use App\Enums\SubscriptionStatus;
use App\Enums\SubscriptionTier;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

test('pricing page is accessible to both guests and authenticated students', function () {
    $this->get(route('pricing'))->assertOk();

    $user = User::factory()->create();
    $this->actingAs($user)
        ->get(route('pricing'))
        ->assertOk();
});

test('checkout page requires authentication and displays plan details', function () {
    $this->get(route('checkout', ['plan' => 'basic']))
        ->assertRedirect(route('login'));

    $user = User::factory()->create();
    $this->actingAs($user)
        ->get(route('checkout', ['plan' => 'basic', 'interval' => 'monthly']))
        ->assertOk();
});

test('checkout validates credit card and plan parameters', function () {
    $user = User::factory()->create();

    $this->actingAs($user)
        ->post(route('checkout.process'), [
            'tier' => 'invalid_tier',
            'interval' => 'monthly',
            'cardholder_name' => '',
            'card_number' => '123',
            'exp_month' => '15',
            'exp_year' => '22',
            'cvc' => '1',
        ])
        ->assertSessionHasErrors(['tier', 'cardholder_name', 'card_number', 'exp_month', 'cvc']);
});

test('successful mock checkout provisions subscription and upgrades user tier', function () {
    $user = User::factory()->create([
        'subscription_tier' => SubscriptionTier::Free,
    ]);

    $response = $this->actingAs($user)
        ->post(route('checkout.process'), [
            'tier' => 'premium',
            'interval' => 'annual',
            'cardholder_name' => 'Alice Student',
            'card_number' => '4242 4242 4242 4242',
            'exp_month' => '12',
            'exp_year' => '28',
            'cvc' => '420',
            'postal_code' => '90210',
        ]);

    $response->assertRedirect(route('dashboard'));
    $response->assertSessionHas('success');

    $user->refresh();
    expect($user->subscription_tier)->toBe(SubscriptionTier::Premium);
    expect($user->subscription_expires_at)->not->toBeNull();
    expect($user->activeSubscription)->not->toBeNull();
    expect($user->activeSubscription->tier)->toBe(SubscriptionTier::Premium);
    expect($user->activeSubscription->status)->toBe(SubscriptionStatus::Active);
    expect($user->activeSubscription->price)->toBe(99.00);
    expect($user->activeSubscription->card_last_four)->toBe('4242');
});

test('user can view subscription settings and cancel their plan', function () {
    $user = User::factory()->scholar()->create();

    $this->actingAs($user)
        ->get(route('subscription.settings'))
        ->assertOk();

    $response = $this->actingAs($user)
        ->post(route('subscription.cancel'));

    $response->assertRedirect(route('subscription.settings'));
    $response->assertSessionHas('success');

    $user->refresh();
    expect($user->subscription_tier)->toBe(SubscriptionTier::Free);
    expect($user->subscription_expires_at)->toBeNull();
});
