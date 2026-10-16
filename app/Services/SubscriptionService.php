<?php

namespace App\Services;

use App\Enums\SubscriptionStatus;
use App\Enums\SubscriptionTier;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class SubscriptionService
{
    /**
     * Generate a cryptographically signed Subscription Passport array.
     *
     * @return array<string, mixed>
     */
    public function generatePassport(User $user): array
    {
        $features = $user->isAdmin()
            ? [SubscriptionTier::FEATURE_CORE, SubscriptionTier::FEATURE_RESOURCES, SubscriptionTier::FEATURE_AI, 'admin:access']
            : $user->subscription_tier->features();

        $payload = [
            'uid' => $user->id,
            'role' => $user->role->value,
            'tier' => $user->subscription_tier->value,
            'tier_label' => $user->subscription_tier->label(),
            'features' => $features,
            'storage_limit_bytes' => $user->storageLimitBytes(),
            'expires_at' => $user->subscription_expires_at?->timestamp,
            'generated_at' => now()->timestamp,
        ];

        $payload['signature'] = $this->signPayload($payload);

        return $payload;
    }

    /**
     * Generate a Sanctum token with the user's subscription passport and tier encoded in its payload.
     *
     * @return array{token: string, token_id: int, device_name: string, payload: array<string, mixed>, passport: array<string, mixed>}
     */
    public function createPassportToken(User $user, string $deviceName = 'Due Mobile'): array
    {
        $passport = $this->generatePassport($user);
        $tier = $user->subscription_tier->value;
        $tierLabel = $user->subscription_tier->label();

        $tokenPayload = [
            'uid' => $user->id,
            'role' => $user->role->value,
            'tier' => $tier,
            'tier_label' => $tierLabel,
            'features' => $passport['features'],
            'storage_limit_bytes' => $user->storageLimitBytes(),
            'iat' => now()->timestamp,
            'exp' => $user->subscription_expires_at?->timestamp,
            'device' => $deviceName,
        ];

        // Base64URL-encoded payload for self-contained token claims
        $encodedPayload = rtrim(strtr(base64_encode(json_encode($tokenPayload, JSON_UNESCAPED_SLASHES)), '+/', '-_'), '=');
        $tokenSecret = Str::random(40);
        $plainTextValue = "{$tokenSecret}.{$encodedPayload}";

        $abilities = array_values(array_unique(array_merge(
            ["tier:{$tier}", "tier_label:{$tierLabel}"],
            $passport['features']
        )));

        $tokenModel = $user->tokens()->create([
            'name' => $deviceName,
            'token' => hash('sha256', $plainTextValue),
            'abilities' => $abilities,
        ]);

        $bearerToken = "{$tokenModel->id}|{$plainTextValue}";
        $tokenModel->forceFill(['plain_token' => $bearerToken])->save();

        return [
            'token' => $bearerToken,
            'token_id' => $tokenModel->id,
            'device_name' => $deviceName,
            'payload' => $tokenPayload,
            'passport' => $passport,
        ];
    }

    /**
     * Verify whether a given passport has a valid HMAC signature and matches the user.
     *
     * @param  array<string, mixed>|null  $passport
     */
    public function verifyPassport(?array $passport, User $user): bool
    {
        if (! $passport || ! isset($passport['signature'], $passport['uid'])) {
            return false;
        }

        if ((int) $passport['uid'] !== $user->id) {
            return false;
        }

        $signature = $passport['signature'];
        $cleanPayload = $passport;
        unset($cleanPayload['signature']);

        return hash_equals($this->signPayload($cleanPayload), $signature);
    }

    /**
     * Compute HMAC-SHA256 signature using the application key.
     *
     * @param  array<string, mixed>  $data
     */
    protected function signPayload(array $data): string
    {
        $appKey = (string) config('app.key');
        if (str_starts_with($appKey, 'base64:')) {
            $appKey = base64_decode(substr($appKey, 7));
        }

        return hash_hmac('sha256', json_encode($data) ?: '', $appKey);
    }

    /**
     * Refresh the user's subscription passport in the session.
     *
     * @return array<string, mixed>
     */
    public function refreshPassportInSession(Request $request, User $user): array
    {
        $passport = $this->generatePassport($user);
        $request->session()->put('subscription_passport', $passport);

        return $passport;
    }

    /**
     * Get Sanctum token abilities based on user tier and role.
     *
     * @return array<string>
     */
    public function getSanctumAbilities(User $user): array
    {
        if ($user->isAdmin()) {
            return [
                SubscriptionTier::FEATURE_CORE,
                SubscriptionTier::FEATURE_RESOURCES,
                SubscriptionTier::FEATURE_AI,
                'admin:access',
            ];
        }

        return $user->subscription_tier->features();
    }

    /**
     * Detect card brand from the card number string.
     */
    public function detectCardBrand(string $cardNumber): string
    {
        $cleaned = preg_replace('/\D/', '', $cardNumber) ?: '';

        if (str_starts_with($cleaned, '4')) {
            return 'visa';
        }
        if (preg_match('/^5[1-5]/', $cleaned) || preg_match('/^2(22[1-9]|2[3-9][0-9]|[3-6][0-9]{2}|7[01][0-9]|720)/', $cleaned)) {
            return 'mastercard';
        }
        if (preg_match('/^3[47]/', $cleaned)) {
            return 'amex';
        }
        if (preg_match('/^6(011|5|4[4-9])/', $cleaned)) {
            return 'discover';
        }

        return 'visa';
    }

    /**
     * Process a mock credit card checkout and provision subscription.
     *
     * @param  array<string, mixed>  $cardData
     */
    public function processMockCheckout(User $user, array $cardData, string $tierValue, string $interval = 'monthly'): Subscription
    {
        $tier = SubscriptionTier::from($tierValue);
        $cleanNumber = preg_replace('/\D/', '', (string) ($cardData['card_number'] ?? '4242')) ?: '4242';
        $lastFour = substr($cleanNumber, -4) ?: '4242';
        $brand = $this->detectCardBrand($cleanNumber);

        $price = $interval === 'annual' ? $tier->annualPrice() : $tier->monthlyPrice();
        $startsAt = now();
        $endsAt = $interval === 'annual' ? now()->addYear() : now()->addMonth();

        // Mark existing active subscriptions as cancelled
        $user->subscriptions()
            ->where('status', SubscriptionStatus::Active)
            ->update([
                'status' => SubscriptionStatus::Cancelled,
                'ends_at' => now(),
            ]);

        // Create new subscription record
        $subscription = Subscription::create([
            'user_id' => $user->id,
            'tier' => $tier,
            'status' => SubscriptionStatus::Active,
            'price' => $price,
            'interval' => $interval === 'annual' ? 'annual' : 'monthly',
            'card_brand' => $brand,
            'card_last_four' => $lastFour,
            'mock_transaction_id' => 'mock_tx_'.Str::random(16),
            'starts_at' => $startsAt,
            'ends_at' => $endsAt,
        ]);

        // Update user's active tier and expiration
        $user->update([
            'subscription_tier' => $tier,
            'subscription_expires_at' => $endsAt,
        ]);

        return $subscription;
    }

    /**
     * Cancel user's active subscription and downgrade to Free tier.
     */
    public function cancelSubscription(User $user): ?Subscription
    {
        $subscription = $user->activeSubscription;

        if ($subscription) {
            $subscription->update([
                'status' => SubscriptionStatus::Cancelled,
                'ends_at' => now(),
            ]);
        }

        $user->update([
            'subscription_tier' => SubscriptionTier::Free,
            'subscription_expires_at' => null,
        ]);

        return $subscription;
    }
}
