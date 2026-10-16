<?php

namespace App\Services;

use App\Enums\SubscriptionStatus;
use App\Enums\SubscriptionTier;
use App\Enums\UserRole;
use App\Models\AiMessage;
use App\Models\Resource;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Support\Carbon;

class AdminStatsService
{
    /**
     * Get high-level system telemetry for the admin dashboard.
     *
     * @return array<string, mixed>
     */
    public function getOverviewStats(): array
    {
        $totalUsers = User::count();
        $geniusUsers = User::where('subscription_tier', SubscriptionTier::Premium)->count();
        $scholarUsers = User::where('subscription_tier', SubscriptionTier::Basic)->count();
        $freeUsers = User::where('subscription_tier', SubscriptionTier::Free)->count();
        $admins = User::where('role', UserRole::Admin)->count();

        $totalStorageBytes = (int) Resource::sum('file_size_bytes');
        $totalResources = Resource::count();

        $totalAiQueries = AiMessage::where('role', 'assistant')->count();
        $totalAiTokens = (int) AiMessage::sum('tokens_used');

        // Calculate simulated MRR & ARR from active subscriptions
        $activeSubs = Subscription::where('status', SubscriptionStatus::Active)->get();
        $simulatedMrr = 0.0;

        foreach ($activeSubs as $sub) {
            if ($sub->interval === 'yearly') {
                $simulatedMrr += ($sub->price / 12);
            } else {
                $simulatedMrr += $sub->price;
            }
        }

        $simulatedArr = $simulatedMrr * 12;

        return [
            'total_users' => $totalUsers,
            'genius_users' => $geniusUsers,
            'scholar_users' => $scholarUsers,
            'free_users' => $freeUsers,
            'admins' => $admins,
            'super_admins' => $admins,
            'total_storage_bytes' => $totalStorageBytes,
            'total_storage_formatted' => $this->formatBytes($totalStorageBytes),
            'total_resources_count' => $totalResources,
            'total_ai_queries' => $totalAiQueries,
            'total_ai_tokens' => $totalAiTokens,
            'simulated_mrr' => round($simulatedMrr, 2),
            'simulated_arr' => round($simulatedArr, 2),
        ];
    }

    /**
     * Get detailed breakdown of platform disk storage consumption.
     *
     * @return array<string, mixed>
     */
    public function getStorageBreakdown(): array
    {
        $categories = [
            'pdf' => ['name' => 'PDF Documents', 'mime_patterns' => ['application/pdf'], 'bytes' => 0, 'count' => 0],
            'image' => ['name' => 'Images', 'mime_patterns' => ['image/%'], 'bytes' => 0, 'count' => 0],
            'code' => ['name' => 'Code & Text', 'mime_patterns' => ['text/%', 'application/json', 'application/javascript', 'application/x-php'], 'bytes' => 0, 'count' => 0],
            'other' => ['name' => 'Other Documents', 'mime_patterns' => [], 'bytes' => 0, 'count' => 0],
        ];

        $resources = Resource::select(['id', 'file_size_bytes', 'mime_type'])->get();

        foreach ($resources as $resource) {
            $matched = false;

            if ($resource->mime_type === 'application/pdf') {
                $categories['pdf']['bytes'] += $resource->file_size_bytes;
                $categories['pdf']['count']++;
                $matched = true;
            } elseif (str_starts_with($resource->mime_type, 'image/')) {
                $categories['image']['bytes'] += $resource->file_size_bytes;
                $categories['image']['count']++;
                $matched = true;
            } elseif (
                str_starts_with($resource->mime_type, 'text/') ||
                in_array($resource->mime_type, ['application/json', 'application/javascript', 'application/x-php'])
            ) {
                $categories['code']['bytes'] += $resource->file_size_bytes;
                $categories['code']['count']++;
                $matched = true;
            }

            if (! $matched) {
                $categories['other']['bytes'] += $resource->file_size_bytes;
                $categories['other']['count']++;
            }
        }

        foreach ($categories as $key => $cat) {
            $categories[$key]['formatted'] = $this->formatBytes($cat['bytes']);
        }

        // Top 10 largest files
        $largestFiles = Resource::with(['user:id,name,email'])
            ->orderBy('file_size_bytes', 'desc')
            ->take(10)
            ->get()
            ->map(fn (Resource $r) => [
                'id' => $r->id,
                'title' => $r->title,
                'file_name' => $r->file_name,
                'file_size_bytes' => $r->file_size_bytes,
                'formatted_size' => $this->formatBytes($r->file_size_bytes),
                'mime_type' => $r->mime_type,
                'owner_name' => $r->user?->name ?? 'Unknown',
                'owner_email' => $r->user?->email ?? 'N/A',
                'created_at' => $r->created_at?->toIso8601String(),
            ]);

        return [
            'categories' => array_values($categories),
            'largest_files' => $largestFiles,
        ];
    }

    /**
     * Get Gemini AI activity telemetry and recent daily query volume.
     *
     * @return array<string, mixed>
     */
    public function getAiTelemetry(): array
    {
        $totalAssistantMessages = AiMessage::where('role', 'assistant')->count();
        $totalTokens = (int) AiMessage::sum('tokens_used');
        $avgTokens = $totalAssistantMessages > 0 ? (int) round($totalTokens / $totalAssistantMessages) : 0;

        // Daily volume for the last 14 days
        $days = [];
        for ($i = 13; $i >= 0; $i--) {
            $date = Carbon::today()->subDays($i);
            $dateKey = $date->format('Y-m-d');
            $label = $date->format('M d');

            $dayTokens = (int) AiMessage::whereDate('created_at', $dateKey)->sum('tokens_used');
            $dayQueries = AiMessage::whereDate('created_at', $dateKey)->where('role', 'assistant')->count();

            $days[] = [
                'date' => $dateKey,
                'label' => $label,
                'tokens' => $dayTokens,
                'queries' => $dayQueries,
            ];
        }

        // Top users by AI token consumption
        $topUsers = User::has('aiConversations')
            ->withCount('aiConversations')
            ->take(8)
            ->get()
            ->map(function (User $user) {
                $userTokens = (int) AiMessage::whereHas('conversation', fn ($q) => $q->where('user_id', $user->id))
                    ->sum('tokens_used');

                return [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'tier' => $user->subscription_tier->value,
                    'conversations_count' => $user->ai_conversations_count,
                    'tokens_used' => $userTokens,
                ];
            })
            ->sortByDesc('tokens_used')
            ->values();

        return [
            'total_queries' => $totalAssistantMessages,
            'total_tokens' => $totalTokens,
            'avg_tokens_per_query' => $avgTokens,
            'daily_stats' => $days,
            'top_users' => $topUsers,
        ];
    }

    /**
     * Get financial and simulated billing overview.
     *
     * @return array<string, mixed>
     */
    public function getSubscriptionsOverview(): array
    {
        $activeCount = Subscription::where('status', SubscriptionStatus::Active)->count();
        $cancelledCount = Subscription::where('status', SubscriptionStatus::Cancelled)->count();
        $expiredCount = Subscription::where('status', SubscriptionStatus::Expired)->count();

        $recentTransactions = Subscription::with(['user:id,name,email'])
            ->orderBy('created_at', 'desc')
            ->take(15)
            ->get()
            ->map(fn (Subscription $s) => [
                'id' => $s->id,
                'user_name' => $s->user?->name ?? 'Unknown',
                'user_email' => $s->user?->email ?? 'N/A',
                'tier' => $s->tier->value,
                'price' => $s->price,
                'interval' => $s->interval,
                'status' => $s->status->value,
                'card_brand' => $s->card_brand,
                'card_last_four' => $s->card_last_four,
                'mock_transaction_id' => $s->mock_transaction_id,
                'starts_at' => $s->starts_at->toIso8601String(),
                'ends_at' => $s->ends_at?->toIso8601String(),
                'created_at' => $s->created_at?->toIso8601String(),
            ]);

        return [
            'active_count' => $activeCount,
            'cancelled_count' => $cancelledCount,
            'expired_count' => $expiredCount,
            'recent_transactions' => $recentTransactions,
        ];
    }

    /**
     * Format raw byte integers into human-readable strings.
     */
    public function formatBytes(int $bytes, int $precision = 2): string
    {
        if ($bytes <= 0) {
            return '0 B';
        }

        $units = ['B', 'KB', 'MB', 'GB', 'TB'];
        $base = log($bytes, 1024);
        $pow = (int) floor($base);

        return round(pow(1024, $base - $pow), $precision).' '.$units[$pow];
    }
}
