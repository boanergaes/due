<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\SubscriptionTier;
use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\SubscriptionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Authenticate user and issue a Sanctum token.
     */
    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'string', 'email'],
            'password' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:100'],
        ]);

        $user = User::where('email', $validated['email'])->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => [__('auth.failed')],
            ]);
        }

        $headerDevice = $request->header('X-Device-Name');
        $deviceName = $validated['device_name'] ?? null;
        if (empty($deviceName) || $deviceName === 'Due Mobile') {
            $deviceName = $headerDevice ?: ($deviceName ?: 'Due Mobile');
        }

        // Prune previous tokens for this device to prevent redundant device entries
        $user->tokens()->where('name', $deviceName)->delete();

        $subscriptionService = app(SubscriptionService::class);
        $passportToken = $subscriptionService->createPassportToken($user, $deviceName);

        return response()->json([
            'message' => 'Authenticated successfully',
            'token' => $passportToken['token'],
            'token_id' => $passportToken['token_id'],
            'device_name' => $passportToken['device_name'],
            'subscription_tier' => $user->subscription_tier->value,
            'subscription_tier_label' => $user->subscription_tier->label(),
            'passport' => $passportToken['passport'],
            'payload' => $passportToken['payload'],
            'abilities' => $passportToken['payload']['features'],
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role->value,
                'subscription_tier' => $user->subscription_tier->value,
                'appearance' => $user->appearance ?? 'dark',
                'created_at' => $user->created_at?->toISOString(),
            ],
        ]);
    }

    /**
     * Register a new student account and issue a token.
     */
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            'device_name' => ['nullable', 'string', 'max:100'],
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'appearance' => 'dark',
            'role' => UserRole::Student,
            'subscription_tier' => SubscriptionTier::Free,
            'email_verified_at' => now(), // Option A: auto-verified
        ]);

        $headerDevice = $request->header('X-Device-Name');
        $deviceName = $validated['device_name'] ?? null;
        if (empty($deviceName) || $deviceName === 'Due Mobile') {
            $deviceName = $headerDevice ?: ($deviceName ?: 'Due Mobile');
        }

        // Prune previous tokens for this device to prevent redundant device entries
        $user->tokens()->where('name', $deviceName)->delete();

        $subscriptionService = app(SubscriptionService::class);
        $passportToken = $subscriptionService->createPassportToken($user, $deviceName);

        return response()->json([
            'message' => 'Account registered successfully',
            'token' => $passportToken['token'],
            'token_id' => $passportToken['token_id'],
            'device_name' => $passportToken['device_name'],
            'subscription_tier' => $user->subscription_tier->value,
            'subscription_tier_label' => $user->subscription_tier->label(),
            'passport' => $passportToken['passport'],
            'payload' => $passportToken['payload'],
            'abilities' => $passportToken['payload']['features'],
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role->value,
                'subscription_tier' => $user->subscription_tier->value,
                'appearance' => $user->appearance,
                'created_at' => $user->created_at?->toISOString(),
            ],
        ], 201);
    }

    /**
     * Log out and revoke the active Sanctum personal access token.
     */
    public function logout(Request $request): JsonResponse
    {
        $user = $request->user();

        // Revoke the specific token used to authenticate this request
        $user?->currentAccessToken()?->delete();

        return response()->json([
            'message' => 'Logged out successfully',
        ]);
    }

    /**
     * Get the authenticated user's profile and summary stats, syncing device name if supplied.
     */
    public function user(Request $request): JsonResponse
    {
        $user = $request->user();

        // If the mobile app provides its real device name via header or query, sync active token name
        $headerDevice = $request->header('X-Device-Name') ?: $request->query('device_name');
        if ($headerDevice && $headerDevice !== 'Due Mobile') {
            $token = $user?->currentAccessToken();
            if ($token && $token->name !== $headerDevice) {
                $token->forceFill(['name' => $headerDevice])->save();
            }
        }

        return response()->json([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'appearance' => $user->appearance ?? 'dark',
                'created_at' => $user->created_at?->toISOString(),
                'classes_count' => $user->classes()->count(),
                'assignments_count' => $user->assignments()->count(),
            ],
            'device_name' => $user?->currentAccessToken()?->name,
        ]);
    }

    /**
     * Explicitly sync the device name of the active mobile token.
     */
    public function syncDevice(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'device_name' => ['required', 'string', 'max:100'],
        ]);

        $token = $request->user()?->currentAccessToken();
        if ($token && $token->name !== $validated['device_name']) {
            $token->forceFill(['name' => $validated['device_name']])->save();
        }

        return response()->json([
            'message' => 'Device synchronized successfully',
            'device_name' => $validated['device_name'],
        ]);
    }

    /**
     * Update and persist the user's appearance preference.
     */
    public function updateAppearance(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'appearance' => ['required', 'string', 'in:light,dark,system'],
        ]);

        $request->user()->update([
            'appearance' => $validated['appearance'],
        ]);

        return response()->json([
            'message' => 'Appearance preference updated successfully',
            'appearance' => $validated['appearance'],
        ]);
    }

    /**
     * Update the user's name and email address.
     */
    public function updateProfile(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users,email,'.$user->id],
        ]);

        $user->fill($validated);
        if ($user->isDirty('email')) {
            $user->email_verified_at = null;
        }
        $user->save();

        return response()->json([
            'message' => 'Profile updated successfully',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role->value,
                'subscription_tier' => $user->subscription_tier->value,
                'appearance' => $user->appearance ?? 'dark',
                'created_at' => $user->created_at?->toISOString(),
            ],
        ]);
    }

    /**
     * Update the user's password.
     */
    public function updatePassword(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'current_password' => ['required', 'string'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ]);

        if (! Hash::check($validated['current_password'], $user->password)) {
            throw ValidationException::withMessages([
                'current_password' => [__('The provided password does not match your current password.')],
            ]);
        }

        $user->update([
            'password' => Hash::make($validated['password']),
        ]);

        return response()->json([
            'message' => 'Password updated successfully',
        ]);
    }

    /**
     * Delete the authenticated user's account.
     */
    public function deleteAccount(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'password' => ['required', 'string'],
        ]);

        if (! Hash::check($validated['password'], $user->password)) {
            throw ValidationException::withMessages([
                'password' => [__('The provided password does not match your current password.')],
            ]);
        }

        $user->tokens()->delete();
        $user->delete();

        return response()->json([
            'message' => 'Account deleted successfully',
        ]);
    }
}
