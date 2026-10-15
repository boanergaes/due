<?php

namespace App\Http\Middleware;

use App\Services\SubscriptionService;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureSubscriptionFeature
{
    public function __construct(
        protected SubscriptionService $subscriptionService
    ) {}

    /**
     * Handle an incoming request.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next, string $feature): Response
    {
        $user = $request->user();

        if (! $user) {
            if ($request->expectsJson() || $request->is('api/*')) {
                return response()->json(['message' => 'Unauthenticated.'], 401);
            }

            return redirect()->guest(route('login'));
        }

        $requiredAbility = str_starts_with($feature, 'feature:') ? $feature : "feature:{$feature}";
        $requiredTier = str_contains($feature, 'ai') ? 'premium' : 'basic';

        // 1. Mobile & Sanctum API Clients: Zero DB queries (abilities are loaded with token auth)
        if ($user->currentAccessToken()) {
            if ($user->tokenCan($requiredAbility) || $user->tokenCan('*')) {
                return $next($request);
            }

            return response()->json([
                'error' => 'Subscription upgrade required',
                'message' => "This feature requires the {$requiredTier} subscription plan.",
                'required_feature' => $requiredAbility,
                'required_tier' => $requiredTier,
            ], 403);
        }

        // 2. Web Clients (Inertia Session): Zero DB queries (verified via cryptographic passport)
        $passport = $request->session()->get('subscription_passport');

        if (! $this->subscriptionService->verifyPassport($passport, $user)) {
            $passport = $this->subscriptionService->refreshPassportInSession($request, $user);
        }

        $features = (array) ($passport['features'] ?? []);
        $role = $passport['role'] ?? 'student';

        if ($role === 'admin' || $role === 'super_admin' || in_array($requiredAbility, $features, true)) {
            return $next($request);
        }

        if ($request->expectsJson() || $request->is('api/*')) {
            return response()->json([
                'error' => 'Subscription upgrade required',
                'message' => "This feature requires the {$requiredTier} subscription plan.",
                'required_feature' => $requiredAbility,
                'required_tier' => $requiredTier,
            ], 403);
        }

        return redirect()->route('pricing')->with('error', "Your current subscription does not include access to this feature. Please upgrade to {$requiredTier}.");
    }
}
