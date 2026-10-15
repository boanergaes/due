<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;
use Inertia\Inertia;
use Inertia\Response;

class AdminAuthController extends Controller
{
    /**
     * Display the dedicated admin login portal.
     */
    public function showLoginForm(Request $request): Response|RedirectResponse
    {
        $user = $request->user();

        if ($user) {
            if ($user->isAdmin()) {
                return redirect()->route('admin.dashboard');
            }

            // Stealth mode: regular students see 404
            abort(404);
        }

        return Inertia::render('admin/login');
    }

    /**
     * Handle admin login attempt with rate limiting and stealth validation.
     */
    public function login(Request $request): RedirectResponse
    {
        // Stealth mode: regular students logged in see 404
        if ($request->user() && ! $request->user()->isAdmin()) {
            abort(404);
        }

        $credentials = $request->validate([
            'email' => ['required', 'string', 'email'],
            'password' => ['required', 'string'],
        ]);

        $throttleKey = 'admin_login_'.Str::transliterate(Str::lower($request->input('email')).'|'.$request->ip());

        if (RateLimiter::tooManyAttempts($throttleKey, 5)) {
            $seconds = RateLimiter::availableIn($throttleKey);

            throw ValidationException::withMessages([
                'email' => trans('auth.throttle', [
                    'seconds' => $seconds,
                    'minutes' => (int) ceil($seconds / 60),
                ]),
            ]);
        }

        $user = User::where('email', $credentials['email'])->first();

        if (! $user || ! Hash::check($credentials['password'], $user->password)) {
            RateLimiter::hit($throttleKey, 60);

            throw ValidationException::withMessages([
                'email' => __('These credentials do not match our administrative records.'),
            ]);
        }

        // Stealth check: if user is not admin, abort with 404
        if (! $user->isAdmin()) {
            RateLimiter::hit($throttleKey, 60);

            Log::warning('Unauthorized account attempted admin portal authentication', [
                'user_id' => $user->id,
                'email' => $user->email,
                'ip' => $request->ip(),
            ]);

            abort(404);
        }

        RateLimiter::clear($throttleKey);

        Auth::login($user, $request->boolean('remember'));
        $request->session()->regenerate();

        return redirect()->intended(route('admin.dashboard'));
    }

    /**
     * Terminate the administrative session.
     */
    public function logout(Request $request): RedirectResponse
    {
        Auth::logout();

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect('/');
    }
}
