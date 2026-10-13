<?php

namespace Database\Factories;

use App\Enums\SubscriptionStatus;
use App\Enums\SubscriptionTier;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<Subscription>
 */
class SubscriptionFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'tier' => SubscriptionTier::Basic,
            'status' => SubscriptionStatus::Active,
            'price' => 4.99,
            'interval' => 'monthly',
            'card_brand' => 'visa',
            'card_last_four' => '4242',
            'mock_transaction_id' => 'mock_tx_'.Str::random(16),
            'starts_at' => now(),
            'ends_at' => now()->addMonth(),
        ];
    }

    /**
     * Indicate that the subscription is for the Genius (Premium) tier.
     */
    public function genius(): static
    {
        return $this->state(fn (array $attributes) => [
            'tier' => SubscriptionTier::Premium,
            'price' => 9.99,
        ]);
    }

    /**
     * Indicate that the subscription is cancelled.
     */
    public function cancelled(): static
    {
        return $this->state(fn (array $attributes) => [
            'status' => SubscriptionStatus::Cancelled,
            'ends_at' => now()->subDay(),
        ]);
    }
}
