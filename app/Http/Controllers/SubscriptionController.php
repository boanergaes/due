<?php

namespace App\Http\Controllers;

use App\Enums\SubscriptionTier;
use App\Services\SubscriptionService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Inertia\Inertia;
use Inertia\Response;

class SubscriptionController extends Controller
{
    public function __construct(
        protected SubscriptionService $subscriptionService
    ) {}

    /**
     * Display the subscription plans & comparison pricing page.
     */
    public function pricing(Request $request): Response
    {
        $user = $request->user();

        return Inertia::render('pricing', [
            'currentTier' => $user?->subscription_tier->value ?? 'free',
            'isAdmin' => $user?->isAdmin() ?? false,
            'isSuperAdmin' => $user?->isAdmin() ?? false,
            'tiers' => [
                [
                    'key' => SubscriptionTier::Free->value,
                    'name' => SubscriptionTier::Free->label(),
                    'tagline' => 'Essential coursework organization for focused students.',
                    'monthlyPrice' => 0,
                    'annualPrice' => 0,
                    'features' => [
                        'Unlimited classes & coursework assignments',
                        'Urgency deadline engine with alert countdowns',
                        'Assignment study notes',
                        'Dark & light mode interface',
                    ],
                    'storageQuota' => '0 MB',
                    'fileUploads' => false,
                    'aiAssistant' => false,
                ],
                [
                    'key' => SubscriptionTier::Basic->value,
                    'name' => SubscriptionTier::Basic->label(),
                    'tagline' => 'Study materials, PDFs, and slide uploads attached to classes and assignments.',
                    'monthlyPrice' => 4.99,
                    'annualPrice' => 49.00,
                    'features' => [
                        'Everything in Free plan',
                        'Upload images, PDFs, and documents per assignment & class',
                        '500 MB total cloud storage quota',
                        'In-browser PDF reader, image lightbox & text preview',
                        'Up to 25 MB single file size limit',
                    ],
                    'storageQuota' => '500 MB',
                    'fileUploads' => true,
                    'aiAssistant' => false,
                ],
                [
                    'key' => SubscriptionTier::Premium->value,
                    'name' => SubscriptionTier::Premium->label(),
                    'tagline' => 'AI study assistant powered by Gemini referencing notes and uploaded resources.',
                    'monthlyPrice' => 9.99,
                    'annualPrice' => 99.00,
                    'popular' => true,
                    'features' => [
                        'Everything in Scholar plan',
                        'Gemini AI Study Copilot for all assignments',
                        'AI reads your notes and uploaded resource files as context',
                        '5 GB total cloud storage quota',
                        'Up to 100 MB single file size limit',
                        'Priority support & early beta features',
                    ],
                    'storageQuota' => '5 GB',
                    'fileUploads' => true,
                    'aiAssistant' => true,
                ],
            ],
        ]);
    }

    /**
     * Show mock checkout page for selected plan.
     */
    public function checkout(Request $request): Response|RedirectResponse
    {
        $plan = $request->query('plan', 'basic');
        if (! in_array($plan, ['basic', 'premium'], true)) {
            $plan = 'basic';
        }

        $interval = $request->query('interval', 'monthly');
        if (! in_array($interval, ['monthly', 'annual'], true)) {
            $interval = 'monthly';
        }

        $tier = SubscriptionTier::from($plan);
        $user = $request->user();

        // If user already on this plan or higher, redirect to settings
        if ($user && $user->subscription_tier === $tier) {
            return redirect()->route('subscription.settings')->with('error', "You are already subscribed to the {$tier->label()} plan.");
        }

        return Inertia::render('checkout', [
            'plan' => $tier->value,
            'planName' => $tier->label(),
            'interval' => $interval,
            'price' => $interval === 'annual' ? $tier->annualPrice() : $tier->monthlyPrice(),
            'monthlyEquivalent' => $interval === 'annual' ? round($tier->annualPrice() / 12, 2) : $tier->monthlyPrice(),
            'features' => $tier->features(),
            'storageLimit' => $tier->storageLimitBytes(),
        ]);
    }

    /**
     * Process mock payment submission.
     */
    public function processCheckout(Request $request): RedirectResponse
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

        $this->subscriptionService->refreshPassportInSession($request, $user);

        return redirect()->route('dashboard')->with(
            'success',
            "Welcome to {$subscription->tier->label()}! Your subscription is active and features are unlocked."
        );
    }

    /**
     * Display current subscription details under Settings.
     */
    public function settings(Request $request): Response
    {
        $user = $request->user();
        $subscription = $user->activeSubscription;

        return Inertia::render('settings/subscription', [
            'currentTier' => $user->subscription_tier->value,
            'tierLabel' => $user->subscription_tier->label(),
            'isAdmin' => $user->isAdmin(),
            'isSuperAdmin' => $user->isAdmin(),
            'subscription' => $subscription ? [
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
            'storageUsedBytes' => $user->storage_used_bytes,
            'storageLimitBytes' => $user->storageLimitBytes(),
            'storageFormatted' => [
                'used' => $this->formatBytes($user->storage_used_bytes),
                'limit' => $user->isAdmin() ? 'Unlimited' : $this->formatBytes($user->storageLimitBytes()),
                'percentage' => $user->storageLimitBytes() > 0 ? min(100, round(($user->storage_used_bytes / $user->storageLimitBytes()) * 100, 1)) : 0,
            ],
            'expiresAt' => $user->subscription_expires_at?->toISOString(),
        ]);
    }

    /**
     * Cancel the user's active subscription.
     */
    public function cancel(Request $request): RedirectResponse
    {
        $user = $request->user();
        $this->subscriptionService->cancelSubscription($user);
        $this->subscriptionService->refreshPassportInSession($request, $user);

        return redirect()->route('subscription.settings')->with(
            'success',
            'Your subscription has been cancelled. Your account has returned to the Free plan.'
        );
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
