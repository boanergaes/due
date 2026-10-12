<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\User;
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

        $deviceName = $validated['device_name'] ?? 'due_mobile_client';
        $token = $user->createToken($deviceName)->plainTextToken;

        return response()->json([
            'message' => 'Authenticated successfully',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
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
            'email_verified_at' => now(), // Option A: auto-verified
        ]);

        $deviceName = $validated['device_name'] ?? 'due_mobile_client';
        $token = $user->createToken($deviceName)->plainTextToken;

        return response()->json([
            'message' => 'Account registered successfully',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
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
     * Get the authenticated user's profile and summary stats.
     */
    public function user(Request $request): JsonResponse
    {
        $user = $request->user();

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
        ]);
    }
}
