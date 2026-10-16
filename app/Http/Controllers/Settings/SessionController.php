<?php

namespace App\Http\Controllers\Settings;

use App\Http\Controllers\Controller;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use Inertia\Inertia;
use Inertia\Response;

class SessionController extends Controller
{
    /**
     * Display the authenticated user's active browser sessions and devices.
     */
    public function edit(Request $request): Response
    {
        $sessions = [];

        if (config('session.driver') === 'database') {
            $lifetime = (int) config('session.lifetime', 120) * 60;
            $cutoff = Carbon::now()->subSeconds($lifetime)->getTimestamp();
            $currentSessionId = $request->session()->getId();

            $allSessions = DB::table('sessions')
                ->where('user_id', $request->user()->getAuthIdentifier())
                ->where('last_activity', '>=', $cutoff)
                ->orderBy('last_activity', 'desc')
                ->get();

            // Deduplicate: If multiple sessions have identical IP and user_agent,
            // keep the current active session or the most recently active one, and remove stale duplicates.
            $seenKeys = [];
            $filteredSessions = collect();
            $staleIdsToDelete = [];

            foreach ($allSessions as $session) {
                $isCurrent = $session->id === $currentSessionId;
                $key = ($session->ip_address ?? 'unknown') . '|' . ($session->user_agent ?? 'unknown');

                if ($isCurrent) {
                    $filteredSessions->prepend($session);
                    $seenKeys[$key] = true;
                } elseif (! isset($seenKeys[$key])) {
                    $seenKeys[$key] = true;
                    $filteredSessions->push($session);
                } else {
                    $staleIdsToDelete[] = $session->id;
                }
            }

            if (! empty($staleIdsToDelete)) {
                DB::table('sessions')->whereIn('id', $staleIdsToDelete)->delete();
            }

            $sessions = $filteredSessions
                ->map(function ($session) use ($request) {
                    $agent = $this->parseUserAgent($session->user_agent);

                    return [
                        'id' => $session->id,
                        'agent' => [
                            'is_desktop' => $agent['is_desktop'],
                            'platform' => $agent['platform'],
                            'browser' => $agent['browser'],
                        ],
                        'ip_address' => $session->ip_address,
                        'is_current_device' => $session->id === $request->session()->getId(),
                        'last_active' => Carbon::createFromTimestamp($session->last_activity)->diffForHumans(),
                    ];
                })
                ->values()
                ->all();
        }

        // Fetch all active personal access tokens / mobile devices
        $rawTokens = $request->user()->tokens()
            ->orderBy('last_used_at', 'desc')
            ->orderBy('created_at', 'desc')
            ->get();

        // Deduplicate devices with identical names (e.g., multiple "Due Mobile" logins),
        // keeping the most recently active token and removing stale redundant entries from DB.
        $seenDeviceNames = [];
        $uniqueTokens = collect();
        $staleTokenIds = [];

        foreach ($rawTokens as $tok) {
            $normalizedName = strtolower(trim($tok->name ?: 'Due Mobile'));
            if (! isset($seenDeviceNames[$normalizedName])) {
                $seenDeviceNames[$normalizedName] = true;
                $uniqueTokens->push($tok);
            } else {
                $staleTokenIds[] = $tok->id;
            }
        }

        if (! empty($staleTokenIds)) {
            $request->user()->tokens()->whereIn('id', $staleTokenIds)->delete();
        }

        $devices = $uniqueTokens
            ->map(function ($token) use ($request) {
                $abilities = (array) $token->abilities;
                $tier = 'free';
                $tierLabel = 'Free Plan';
                foreach ($abilities as $ability) {
                    if (str_starts_with($ability, 'tier:')) {
                        $tier = substr($ability, 5);
                    }
                    if (str_starts_with($ability, 'tier_label:')) {
                        $tierLabel = substr($ability, 11);
                    }
                }

                if ($tier === 'free' && $request->user()->subscription_tier) {
                    $tier = $request->user()->subscription_tier->value;
                    $tierLabel = $request->user()->subscription_tier->label();
                }

                if (! str_ends_with(strtolower($tierLabel), 'plan')) {
                    $tierLabel .= ' Plan';
                }

                $plainToken = $token->plain_token;
                $maskedToken = null;
                if ($plainToken) {
                    if (str_contains($plainToken, '|')) {
                        [$idPrefix, $secretPart] = explode('|', $plainToken, 2);
                        if (strlen($secretPart) > 10) {
                            $prefix = substr($secretPart, 0, 4);
                            $suffix = substr($secretPart, -4);
                            $maskedToken = "{$idPrefix}|{$prefix}...{$suffix}";
                        } else {
                            $maskedToken = "{$idPrefix}|••••••••";
                        }
                    } else {
                        $prefix = substr($plainToken, 0, 4);
                        $suffix = substr($plainToken, -4);
                        $maskedToken = "{$prefix}...{$suffix}";
                    }
                } else {
                    $maskedToken = "{$token->id}|••••...••••";
                }

                return [
                    'id' => $token->id,
                    'name' => $token->name ?: 'Due Mobile',
                    'type' => 'mobile',
                    'is_mobile' => true,
                    'is_current_device' => false,
                    'subscription_tier' => $tier,
                    'subscription_tier_label' => $tierLabel,
                    'token_masked' => $maskedToken,
                    'token_full' => $plainToken ?? '',
                    'abilities' => $abilities,
                    'last_used_at' => $token->last_used_at
                        ? Carbon::parse($token->last_used_at)->diffForHumans()
                        : 'Recently added',
                    'created_at' => Carbon::parse($token->created_at)->diffForHumans(),
                ];
            })
            ->values()
            ->all();

        $userTier = $request->user()->subscription_tier?->value ?? 'free';
        $userTierLabel = ($request->user()->subscription_tier?->label() ?? 'Free') . ' Plan';

        // Build a unified collection combining both browser sessions and mobile devices
        $allSessions = [];

        foreach ($sessions as $session) {
            $allSessions[] = [
                'id' => (string) $session['id'],
                'name' => "{$session['agent']['platform']} — {$session['agent']['browser']}",
                'type' => 'browser',
                'is_current_device' => $session['is_current_device'],
                'subscription_tier' => $userTier,
                'subscription_tier_label' => $userTierLabel,
                'token_masked' => null,
                'token_full' => null,
                'ip_address' => $session['ip_address'],
                'last_active' => $session['last_active'],
                'created_at' => null,
                'agent' => $session['agent'],
            ];
        }

        foreach ($devices as $device) {
            $allSessions[] = [
                'id' => (string) $device['id'],
                'device_token_id' => $device['id'],
                'name' => $device['name'],
                'type' => 'mobile',
                'is_current_device' => false,
                'subscription_tier' => $device['subscription_tier'],
                'subscription_tier_label' => $device['subscription_tier_label'],
                'token_masked' => $device['token_masked'],
                'token_full' => $device['token_full'],
                'ip_address' => null,
                'last_active' => $device['last_used_at'],
                'created_at' => $device['created_at'],
                'agent' => [
                    'is_desktop' => false,
                    'platform' => 'Mobile',
                    'browser' => 'Mobile App',
                ],
            ];
        }

        // Keep current session first, followed by others
        usort($allSessions, function ($a, $b) {
            if ($a['is_current_device']) return -1;
            if ($b['is_current_device']) return 1;
            return 0;
        });

        return Inertia::render('settings/sessions', [
            'sessions' => $sessions,
            'devices' => $devices,
            'allSessions' => $allSessions,
            'sessionDriver' => config('session.driver'),
        ]);
    }

    /**
     * Log out all other browser sessions for the user.
     */
    public function destroyOtherSessions(Request $request): RedirectResponse
    {
        $request->validate([
            'password' => ['required', 'string'],
        ]);

        if (! Hash::check($request->password, $request->user()->password)) {
            throw ValidationException::withMessages([
                'password' => [__('The provided password does not match our records.')],
            ]);
        }

        Auth::logoutOtherDevices($request->password);

        if (config('session.driver') === 'database') {
            DB::table('sessions')
                ->where('user_id', $request->user()->getAuthIdentifier())
                ->where('id', '!=', $request->session()->getId())
                ->delete();
        }

        return back()->with('success', 'Logged out of all other device sessions.');
    }

    /**
     * Terminate a specific browser session by ID.
     */
    public function destroySession(Request $request, string $sessionId): RedirectResponse
    {
        if ($sessionId === $request->session()->getId()) {
            return back()->with('error', 'Cannot terminate your current active session from here. Use log out instead.');
        }

        if (config('session.driver') === 'database') {
            DB::table('sessions')
                ->where('user_id', $request->user()->getAuthIdentifier())
                ->where('id', $sessionId)
                ->delete();
        }

        return back()->with('success', 'Device session terminated.');
    }

    /**
     * Revoke a specific personal access token / mobile device.
     */
    public function destroyDeviceToken(Request $request, int|string $tokenId): RedirectResponse
    {
        $token = $request->user()->tokens()->where('id', $tokenId)->first();

        if ($token) {
            $token->delete();

            return back()->with('success', 'Mobile device token revoked.');
        }

        return back()->with('error', 'Device token not found or already revoked.');
    }

    /**
     * Revoke all personal access tokens / mobile devices.
     */
    public function destroyAllDeviceTokens(Request $request): RedirectResponse
    {
        $request->user()->tokens()->delete();

        return back()->with('success', 'All mobile device tokens have been revoked.');
    }

    /**
     * Parse user agent string into readable platform, browser, and device classification.
     */
    protected function parseUserAgent(?string $userAgent): array
    {
        if (empty($userAgent)) {
            return [
                'is_desktop' => true,
                'platform' => 'Unknown OS',
                'browser' => 'Unknown Browser',
            ];
        }

        // Platform detection (check mobile devices first because iOS user agents include 'Mac OS X')
        $platform = 'Unknown OS';
        if (preg_match('/iphone|ipad|ipod/i', $userAgent)) {
            $platform = 'iOS';
        } elseif (preg_match('/android/i', $userAgent)) {
            $platform = 'Android';
        } elseif (preg_match('/windows|win32/i', $userAgent)) {
            $platform = 'Windows';
        } elseif (preg_match('/macintosh|mac os x/i', $userAgent)) {
            $platform = 'macOS';
        } elseif (preg_match('/linux/i', $userAgent)) {
            $platform = 'Linux';
        }

        // Browser detection
        $browser = 'Unknown Browser';
        if (preg_match('/edg/i', $userAgent)) {
            $browser = 'Edge';
        } elseif (preg_match('/chrome/i', $userAgent) && ! preg_match('/edg/i', $userAgent)) {
            $browser = 'Chrome';
        } elseif (preg_match('/firefox/i', $userAgent)) {
            $browser = 'Firefox';
        } elseif (preg_match('/safari/i', $userAgent) && ! preg_match('/chrome/i', $userAgent)) {
            $browser = 'Safari';
        } elseif (preg_match('/opera|opr/i', $userAgent)) {
            $browser = 'Opera';
        }

        $isDesktop = ! preg_match('/mobile|android|iphone|ipad|ipod/i', $userAgent);

        return [
            'is_desktop' => $isDesktop,
            'platform' => $platform,
            'browser' => $browser,
        ];
    }
}
