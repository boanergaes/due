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
            $sessions = DB::table('sessions')
                ->where('user_id', $request->user()->getAuthIdentifier())
                ->orderBy('last_activity', 'desc')
                ->get()
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

        return Inertia::render('settings/sessions', [
            'sessions' => $sessions,
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
