<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\SubscriptionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Laravel\Sanctum\PersonalAccessToken;
use Mockery\MockInterface;

class SubscriptionApiController extends Controller
{
    public function __construct(
        protected SubscriptionService $subscriptionService
    ) {}

    /**
     * Get current user's subscription, abilities, and storage quota status.
     */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $subscription = $user->activeSubscription;

        return response()->json([
            'tier' => $user->subscription_tier->value,
            'tier_label' => $user->subscription_tier->label(),
            'is_admin' => $user->isAdmin(),
            'is_super_admin' => $user->isAdmin(),
            'abilities' => $this->subscriptionService->getSanctumAbilities($user),
            'storage' => [
                'used_bytes' => $user->storage_used_bytes,
                'limit_bytes' => $user->storageLimitBytes(),
                'used_formatted' => $this->formatBytes($user->storage_used_bytes),
                'limit_formatted' => $user->isAdmin() ? 'Unlimited' : $this->formatBytes($user->storageLimitBytes()),
                'percentage' => $user->storageLimitBytes() > 0 ? min(100, round(($user->storage_used_bytes / $user->storageLimitBytes()) * 100, 1)) : 0,
            ],
            'expires_at' => $user->subscription_expires_at?->toISOString(),
            'active_subscription' => $subscription ? [
                'id' => $subscription->id,
                'tier' => $subscription->tier->value,
                'status' => $subscription->status->value,
                'price' => $subscription->price,
                'interval' => $subscription->interval,
                'card_brand' => $subscription->card_brand,
                'card_last_four' => $subscription->card_last_four,
                'starts_at' => $subscription->starts_at->toISOString(),
                'ends_at' => $subscription->ends_at?->toISOString(),
            ] : null,
        ]);
    }

    /**
     * Execute mock credit card checkout and update token abilities.
     */
    public function checkout(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'tier' => ['required', 'string', Rule::in(['basic', 'premium'])],
            'interval' => ['required', 'string', Rule::in(['monthly', 'annual'])],
            'cardholder_name' => ['required', 'string', 'max:100'],
            'card_number' => ['required', 'string', 'min:12', 'max:26'],
            'exp_month' => ['required', 'string', 'regex:/^(0[1-9]|1[0-2])$/'],
            'exp_year' => ['required', 'string', 'regex:/^([0-9]{2}|[0-9]{4})$/'],
            'cvc' => ['required', 'string', 'min:3', 'max:4'],
            'postal_code' => ['nullable', 'string', 'max:20'],
        ]);

        $user = $request->user();
        $subscription = $this->subscriptionService->processMockCheckout(
            user: $user,
            cardData: $validated,
            tierValue: $validated['tier'],
            interval: $validated['interval']
        );

        // Update active Sanctum token's abilities instantly in DB if persistent
        $newAbilities = $this->subscriptionService->getSanctumAbilities($user);
        $token = $user->currentAccessToken();
        if ($token instanceof PersonalAccessToken && ! ($token instanceof MockInterface)) {
            $token->forceFill(['abilities' => $newAbilities])->save();
        }

        return response()->json([
            'message' => "Successfully subscribed to {$subscription->tier->label()} plan.",
            'tier' => $user->subscription_tier->value,
            'tier_label' => $user->subscription_tier->label(),
            'abilities' => $newAbilities,
            'subscription' => [
                'id' => $subscription->id,
                'tier' => $subscription->tier->value,
                'status' => $subscription->status->value,
                'price' => $subscription->price,
                'interval' => $subscription->interval,
                'card_brand' => $subscription->card_brand,
                'card_last_four' => $subscription->card_last_four,
                'mock_transaction_id' => $subscription->mock_transaction_id,
                'starts_at' => $subscription->starts_at->toISOString(),
                'ends_at' => $subscription->ends_at?->toISOString(),
            ],
        ], 200);
    }

    /**
     * Cancel active subscription.
     */
    public function cancel(Request $request): JsonResponse
    {
        $user = $request->user();
        $this->subscriptionService->cancelSubscription($user);

        // Reset token abilities back to Free tier
        $newAbilities = $this->subscriptionService->getSanctumAbilities($user);
        $token = $user->currentAccessToken();
        if ($token instanceof PersonalAccessToken && ! ($token instanceof MockInterface)) {
            $token->forceFill(['abilities' => $newAbilities])->save();
        }

        return response()->json([
            'message' => 'Subscription cancelled successfully. Account returned to Free tier.',
            'tier' => $user->subscription_tier->value,
            'abilities' => $newAbilities,
        ]);
    }

    protected function formatBytes(int $bytes): string
    {
        if ($bytes >= 1_073_741_824) {
            return number_format($bytes / 1_073_741_824, 2).' GB';
        }
        if ($bytes >= 1_048_576) {
            return number_format($bytes / 1_048_576, 1).' MB';
        }
        if ($bytes >= 1024) {
            return number_format($bytes / 1024, 0).' KB';
        }

        return $bytes.' B';
    }
}
