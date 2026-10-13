<?php

namespace App\Http\Middleware;

use Illuminate\Http\Request;
use Inertia\Middleware;

class HandleInertiaRequests extends Middleware
{
    /**
     * The root template that's loaded on the first page visit.
     *
     * @see https://inertiajs.com/server-side-setup#root-template
     *
     * @var string
     */
    protected $rootView = 'app';

    /**
     * Determines the current asset version.
     *
     * @see https://inertiajs.com/asset-versioning
     */
    public function version(Request $request): ?string
    {
        return parent::version($request);
    }

    /**
     * Define the props that are shared by default.
     *
     * @see https://inertiajs.com/shared-data
     *
     * @return array<string, mixed>
     */
    public function share(Request $request): array
    {
        return [
            ...parent::share($request),
            'name' => config('app.name'),
            'auth' => [
                'user' => $request->user(),
            ],
            'appearance' => $request->user()?->appearance ?? $request->cookie('appearance') ?? 'dark',
            'subscription' => fn () => $request->user() ? [
                'tier' => $request->user()->subscription_tier->value,
                'tier_label' => $request->user()->subscription_tier->label(),
                'role' => $request->user()->role->value,
                'is_super_admin' => $request->user()->isSuperAdmin(),
                'features' => $request->user()->isSuperAdmin()
                    ? ['feature:core', 'feature:resources', 'feature:ai', 'admin:access']
                    : $request->user()->subscription_tier->features(),
                'storage_used_bytes' => $request->user()->storage_used_bytes,
                'storage_limit_bytes' => $request->user()->storageLimitBytes(),
                'expires_at' => $request->user()->subscription_expires_at?->toISOString(),
            ] : null,
            'flash' => [
                'success' => fn () => $request->session()->get('success'),
                'error' => fn () => $request->session()->get('error'),
            ],
            'sidebarOpen' => ! $request->hasCookie('sidebar_state') || $request->cookie('sidebar_state') === 'true',
        ];
    }
}
