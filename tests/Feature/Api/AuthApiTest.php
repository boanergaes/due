<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register_and_receive_sanctum_token(): void
    {
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'John Student',
            'email' => 'student@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'device_name' => 'Pixel 8',
        ]);

        $response->assertCreated();
        $response->assertJsonStructure([
            'message',
            'token',
            'user' => ['id', 'name', 'email', 'appearance'],
        ]);

        $this->assertDatabaseHas('users', [
            'email' => 'student@example.com',
            'name' => 'John Student',
        ]);

        $token = $response->json('token');

        // Test token works for protected routes
        $protectedResponse = $this->withToken($token)->getJson('/api/v1/auth/user');
        $protectedResponse->assertOk();
        $protectedResponse->assertJsonPath('user.email', 'student@example.com');
    }

    public function test_registration_validates_required_fields_and_unique_email(): void
    {
        User::factory()->create(['email' => 'existing@example.com']);

        $response = $this->postJson('/api/v1/auth/register', [
            'name' => '',
            'email' => 'existing@example.com',
            'password' => 'short',
            'password_confirmation' => 'mismatch',
        ]);

        $response->assertUnprocessable();
        $response->assertJsonValidationErrors(['name', 'email', 'password']);
    }

    public function test_user_can_login_with_valid_credentials(): void
    {
        $user = User::factory()->create([
            'email' => 'student@example.com',
            'password' => Hash::make('secret-password'),
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'student@example.com',
            'password' => 'secret-password',
            'device_name' => 'iPhone 15',
        ]);

        $response->assertOk();
        $response->assertJsonStructure([
            'message',
            'token',
            'user' => ['id', 'name', 'email', 'appearance'],
        ]);

        $this->assertNotNull($response->json('token'));
    }

    public function test_login_fails_with_invalid_password(): void
    {
        User::factory()->create([
            'email' => 'student@example.com',
            'password' => Hash::make('correct-password'),
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'student@example.com',
            'password' => 'wrong-password',
        ]);

        $response->assertUnprocessable();
        $response->assertJsonValidationErrors(['email']);
    }

    public function test_guest_cannot_access_protected_auth_endpoints(): void
    {
        $response = $this->getJson('/api/v1/auth/user');
        $response->assertUnauthorized();
    }

    public function test_user_can_update_appearance_preference(): void
    {
        $user = User::factory()->create(['appearance' => 'dark']);
        $token = $user->createToken('test')->plainTextToken;

        $response = $this->withToken($token)->patchJson('/api/v1/auth/appearance', [
            'appearance' => 'light',
        ]);

        $response->assertOk();
        $response->assertJsonPath('appearance', 'light');

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'appearance' => 'light',
        ]);
    }

    public function test_user_can_logout_and_revoke_token(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        $this->assertCount(1, $user->tokens);

        $response = $this->withToken($token)->postJson('/api/v1/auth/logout');
        $response->assertOk();

        $this->assertCount(0, $user->fresh()->tokens);
    }
}
