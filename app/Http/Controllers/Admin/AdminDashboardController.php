<?php

namespace App\Http\Controllers\Admin;

use App\Enums\SubscriptionStatus;
use App\Enums\SubscriptionTier;
use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\Resource;
use App\Models\Subscription;
use App\Models\User;
use App\Services\AdminStatsService;
use App\Services\SubscriptionService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Inertia\Inertia;
use Inertia\Response;

class AdminDashboardController extends Controller
{
    /**
     * Display the primary administrative dashboard.
     */
    public function index(AdminStatsService $statsService): Response
    {
        return Inertia::render('admin/dashboard', [
            'overview' => $statsService->getOverviewStats(),
            'storage' => $statsService->getStorageBreakdown(),
            'ai' => $statsService->getAiTelemetry(),
            'subscriptions' => $statsService->getSubscriptionsOverview(),
        ]);
    }

    /**
     * Display searchable, filterable user directory.
     */
    public function users(Request $request): Response
    {
        $search = trim((string) $request->input('search', ''));
        $tier = $request->input('tier');
        $role = $request->input('role');

        $query = User::query()
            ->withCount(['classes', 'assignments', 'resources', 'aiConversations'])
            ->orderBy('created_at', 'desc');

        if (! empty($search)) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('email', 'like', "%{$search}%");
            });
        }

        if (! empty($tier) && in_array($tier, SubscriptionTier::values(), true)) {
            $query->where('subscription_tier', $tier);
        }

        if (! empty($role) && in_array($role, UserRole::values(), true)) {
            $query->where('role', $role);
        }

        $users = $query->paginate(15)->withQueryString();

        return Inertia::render('admin/users', [
            'users' => $users,
            'filters' => [
                'search' => $search,
                'tier' => $tier,
                'role' => $role,
            ],
            'tiers' => array_map(fn (SubscriptionTier $t) => [
                'value' => $t->value,
                'label' => $t->label(),
            ], SubscriptionTier::cases()),
            'roles' => array_map(fn (UserRole $r) => [
                'value' => $r->value,
                'label' => $r->label(),
            ], UserRole::cases()),
        ]);
    }

    /**
     * Override a user's subscription tier instantly.
     */
    public function updateUserTier(
        Request $request,
        User $user,
        SubscriptionService $subscriptionService
    ): RedirectResponse {
        $validated = $request->validate([
            'tier' => ['required', 'string', 'in:free,premium'],
            'interval' => ['nullable', 'string', 'in:monthly,yearly'],
        ]);

        $newTier = SubscriptionTier::from($validated['tier']);

        if ($newTier === SubscriptionTier::Premium) {
            $user->subscription_tier = SubscriptionTier::Premium;
            $user->subscription_expires_at = now()->addYear();
            $user->save();

            // Create or update mock subscription record for telemetry & audit
            Subscription::create([
                'user_id' => $user->id,
                'tier' => SubscriptionTier::Premium,
                'status' => SubscriptionStatus::Active,
                'price' => $validated['interval'] === 'yearly' ? 99.99 : 9.99,
                'interval' => $validated['interval'] ?? 'monthly',
                'card_brand' => 'admin_override',
                'card_last_four' => '9999',
                'mock_transaction_id' => 'adm_'.Str::random(18),
                'starts_at' => now(),
                'ends_at' => now()->addYear(),
            ]);
        } else {
            $user->subscription_tier = SubscriptionTier::Free;
            $user->subscription_expires_at = null;
            $user->save();

            // Cancel any active subscriptions
            $user->subscriptions()
                ->where('status', SubscriptionStatus::Active)
                ->update(['status' => SubscriptionStatus::Cancelled]);
        }

        // Refresh token passport
        $subscriptionService->generatePassport($user);

        return back()->with('success', "Subscription tier for {$user->name} was updated to {$newTier->label()}.");
    }

    /**
     * Override a user's role (promote/demote admin).
     */
    public function updateUserRole(Request $request, User $user): RedirectResponse
    {
        $validated = $request->validate([
            'role' => ['required', 'string', 'in:student,admin'],
        ]);

        $newRole = UserRole::from($validated['role']);

        // Prevent demoting the last admin
        if ($user->role === UserRole::Admin && $newRole !== UserRole::Admin) {
            $adminCount = User::where('role', UserRole::Admin)->count();
            if ($adminCount <= 1) {
                return back()->with('error', 'Cannot demote the only remaining Administrator.');
            }
        }

        $user->role = $newRole;
        $user->save();

        return back()->with('success', "Role for {$user->name} was changed to {$newRole->label()}.");
    }

    /**
     * Clear all AI conversation history for a specific user.
     */
    public function clearUserAi(User $user): RedirectResponse
    {
        $user->aiConversations()->delete();

        return back()->with('success', "Cleared all AI conversations and study history for {$user->name}.");
    }

    /**
     * Display mock subscription audit logs and revenue metrics.
     */
    public function subscriptions(AdminStatsService $statsService): Response
    {
        $subscriptions = Subscription::with(['user:id,name,email'])
            ->orderBy('created_at', 'desc')
            ->paginate(15);

        return Inertia::render('admin/subscriptions', [
            'metrics' => $statsService->getSubscriptionsOverview(),
            'overview' => $statsService->getOverviewStats(),
            'subscriptions' => $subscriptions,
        ]);
    }

    /**
     * Display comprehensive storage audit and largest files.
     */
    public function storage(AdminStatsService $statsService): Response
    {
        return Inertia::render('admin/storage', [
            'breakdown' => $statsService->getStorageBreakdown(),
            'overview' => $statsService->getOverviewStats(),
        ]);
    }

    /**
     * Administratively delete an uploaded resource.
     */
    public function deleteResource(Resource $resource): RedirectResponse
    {
        $owner = $resource->user;
        $bytes = $resource->file_size_bytes;

        // Delete file from disk
        if (Storage::disk('public')->exists($resource->file_path)) {
            Storage::disk('public')->delete($resource->file_path);
        }

        // Deduct from owner storage quota
        if ($owner) {
            $owner->storage_used_bytes = max(0, $owner->storage_used_bytes - $bytes);
            $owner->save();
        }

        $resourceTitle = $resource->title;
        $resource->delete();

        return back()->with('success', "Resource '{$resourceTitle}' was deleted and user quota was restored.");
    }
}
