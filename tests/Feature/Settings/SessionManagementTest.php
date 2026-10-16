<?php

namespace Tests\Feature\Settings;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Inertia\Testing\AssertableInertia as Assert;
use Tests\TestCase;

class SessionManagementTest extends TestCase
{
    use RefreshDatabase;

    public function test_guests_cannot_access_session_settings(): void
    {
        $response = $this->get(route('sessions.edit'));
        $response->assertRedirect(route('login'));
    }

    public function test_authenticated_user_can_view_sessions_page(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)->get(route('sessions.edit'));

        $response->assertOk();
        $response->assertInertia(fn (Assert $page) => $page
            ->component('settings/sessions')
            ->has('sessions')
        );
    }

    public function test_user_can_view_active_database_sessions(): void
    {
        config(['session.driver' => 'database']);

        $user = User::factory()->create();

        // Seed 2 sessions for the user
        DB::table('sessions')->insert([
            [
                'id' => 'session_1',
                'user_id' => $user->id,
                'ip_address' => '127.0.0.1',
                'user_agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'payload' => serialize(['foo' => 'bar']),
                'last_activity' => time(),
            ],
            [
                'id' => 'session_2',
                'user_id' => $user->id,
                'ip_address' => '192.168.1.50',
                'user_agent' => 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148 Safari/604.1',
                'payload' => serialize(['foo' => 'baz']),
                'last_activity' => time() - 3600,
            ],
        ]);

        $response = $this->actingAs($user)->get(route('sessions.edit'));

        $response->assertOk();
        $response->assertInertia(fn (Assert $page) => $page
            ->component('settings/sessions')
            ->has('sessions', 2)
            ->where('sessions.0.agent.platform', 'macOS')
            ->where('sessions.0.agent.browser', 'Chrome')
            ->where('sessions.1.agent.platform', 'iOS')
            ->where('sessions.1.agent.browser', 'Safari')
        );
    }

    public function test_cannot_logout_other_sessions_with_wrong_password(): void
    {
        config(['session.driver' => 'database']);

        $user = User::factory()->create([
            'password' => Hash::make('secret-password'),
        ]);

        $response = $this->actingAs($user)->delete(route('sessions.destroy-others'), [
            'password' => 'incorrect-password',
        ]);

        $response->assertSessionHasErrors(['password']);
    }

    public function test_can_logout_other_sessions_with_correct_password(): void
    {
        config(['session.driver' => 'database']);

        $user = User::factory()->create([
            'password' => Hash::make('secret-password'),
        ]);

        // Insert sessions
        DB::table('sessions')->insert([
            [
                'id' => 'current_session_id',
                'user_id' => $user->id,
                'ip_address' => '127.0.0.1',
                'user_agent' => 'Chrome',
                'payload' => serialize([]),
                'last_activity' => time(),
            ],
            [
                'id' => 'other_session_id',
                'user_id' => $user->id,
                'ip_address' => '10.0.0.1',
                'user_agent' => 'Safari',
                'payload' => serialize([]),
                'last_activity' => time() - 1000,
            ],
        ]);

        $response = $this->actingAs($user)
            ->withSession(['_token' => 'test'])
            ->delete(route('sessions.destroy-others'), [
                'password' => 'secret-password',
            ]);

        $response->assertSessionHasNoErrors();
        $response->assertRedirect();

        // Other session was deleted
        $this->assertDatabaseMissing('sessions', ['id' => 'other_session_id']);
    }

    public function test_can_revoke_single_other_session_by_id(): void
    {
        config(['session.driver' => 'database']);

        $user = User::factory()->create();

        DB::table('sessions')->insert([
            'id' => 'foreign_device_session',
            'user_id' => $user->id,
            'ip_address' => '10.0.0.2',
            'user_agent' => 'Firefox',
            'payload' => serialize([]),
            'last_activity' => time() - 500,
        ]);

        $response = $this->actingAs($user)->delete(route('sessions.destroy', 'foreign_device_session'));

        $response->assertSessionHasNoErrors();
        $this->assertDatabaseMissing('sessions', ['id' => 'foreign_device_session']);
    }

    public function test_cannot_revoke_another_users_session(): void
    {
        config(['session.driver' => 'database']);

        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        DB::table('sessions')->insert([
            'id' => 'user_2_session',
            'user_id' => $user2->id,
            'ip_address' => '10.0.0.3',
            'user_agent' => 'Firefox',
            'payload' => serialize([]),
            'last_activity' => time(),
        ]);

        $this->actingAs($user1)->delete(route('sessions.destroy', 'user_2_session'));

        // user2's session must still exist untouched
        $this->assertDatabaseHas('sessions', ['id' => 'user_2_session']);
    }

    public function test_user_can_view_active_mobile_device_tokens_with_subscription_tier(): void
    {
        $user = User::factory()->create([
            'subscription_tier' => \App\Enums\SubscriptionTier::Basic,
        ]);

        // Issue a mobile passport token
        $passportService = app(\App\Services\SubscriptionService::class);
        $passportService->createPassportToken($user, 'SM A165F (Android)');

        $response = $this->actingAs($user)->get(route('sessions.edit'));

        $response->assertOk();
        $response->assertInertia(fn (Assert $page) => $page
            ->component('settings/sessions')
            ->has('devices', 1)
            ->where('devices.0.name', 'SM A165F (Android)')
            ->where('devices.0.subscription_tier', 'basic')
            ->where('devices.0.is_mobile', true)
        );
    }

    public function test_redundant_web_sessions_with_same_ip_and_agent_are_deduplicated(): void
    {
        config(['session.driver' => 'database']);

        $user = User::factory()->create();

        // Seed 3 sessions with the identical IP and user agent
        DB::table('sessions')->insert([
            [
                'id' => 'session_dupe_1',
                'user_id' => $user->id,
                'ip_address' => '192.168.1.100',
                'user_agent' => 'Mozilla/5.0 (Linux; Android 14) Chrome/120.0 Mobile',
                'payload' => serialize([]),
                'last_activity' => time() - 100,
            ],
            [
                'id' => 'session_dupe_2',
                'user_id' => $user->id,
                'ip_address' => '192.168.1.100',
                'user_agent' => 'Mozilla/5.0 (Linux; Android 14) Chrome/120.0 Mobile',
                'payload' => serialize([]),
                'last_activity' => time() - 50, // More recent
            ],
            [
                'id' => 'session_dupe_3',
                'user_id' => $user->id,
                'ip_address' => '192.168.1.100',
                'user_agent' => 'Mozilla/5.0 (Linux; Android 14) Chrome/120.0 Mobile',
                'payload' => serialize([]),
                'last_activity' => time() - 300,
            ],
        ]);

        $response = $this->actingAs($user)->get(route('sessions.edit'));

        $response->assertOk();
        $response->assertInertia(fn (Assert $page) => $page
            ->component('settings/sessions')
            ->has('sessions', 1)
            ->where('sessions.0.id', 'session_dupe_2')
        );

        // Stale duplicate sessions were pruned
        $this->assertDatabaseMissing('sessions', ['id' => 'session_dupe_1']);
        $this->assertDatabaseMissing('sessions', ['id' => 'session_dupe_3']);
    }

    public function test_can_revoke_single_device_token(): void
    {
        $user = User::factory()->create();
        $passportService = app(\App\Services\SubscriptionService::class);
        $result = $passportService->createPassportToken($user, 'SM A165F (Android)');

        $this->assertCount(1, $user->tokens);

        $response = $this->actingAs($user)->delete(route('devices.destroy', $result['token_id']));

        $response->assertRedirect();
        $this->assertCount(0, $user->fresh()->tokens);
    }

    public function test_can_revoke_all_device_tokens(): void
    {
        $user = User::factory()->create();
        $passportService = app(\App\Services\SubscriptionService::class);
        $passportService->createPassportToken($user, 'Device 1');
        $passportService->createPassportToken($user, 'Device 2');

        $this->assertCount(2, $user->tokens);

        $response = $this->actingAs($user)->delete(route('devices.destroy-all'));

        $response->assertRedirect();
        $this->assertCount(0, $user->fresh()->tokens);
    }

    public function test_redundant_mobile_tokens_with_same_device_name_are_deduplicated(): void
    {
        $user = User::factory()->create();
        $passportService = app(\App\Services\SubscriptionService::class);

        // Simulate multiple logins on the same device creating redundant tokens
        $passportService->createPassportToken($user, 'Due Mobile');
        $passportService->createPassportToken($user, 'Due Mobile');
        $passportService->createPassportToken($user, 'Due Mobile');

        $this->assertCount(3, $user->tokens);

        $response = $this->actingAs($user)->get(route('sessions.edit'));

        $response->assertOk();
        $response->assertInertia(fn (Assert $page) => $page
            ->component('settings/sessions')
            ->has('devices', 1)
            ->where('devices.0.name', 'Due Mobile')
        );

        // Stale redundant tokens pruned from DB
        $this->assertCount(1, $user->fresh()->tokens);
    }

    public function test_mobile_devices_include_masked_token_and_plan_label(): void
    {
        $user = User::factory()->create([
            'subscription_tier' => \App\Enums\SubscriptionTier::Premium,
        ]);
        $passportService = app(\App\Services\SubscriptionService::class);
        $passportService->createPassportToken($user, 'Samsung SM-A165F');

        $response = $this->actingAs($user)->get(route('sessions.edit'));

        $response->assertOk();
        $response->assertInertia(fn (Assert $page) => $page
            ->component('settings/sessions')
            ->has('devices', 1)
            ->where('devices.0.name', 'Samsung SM-A165F')
            ->where('devices.0.subscription_tier_label', 'Genius Plan')
            ->has('devices.0.token_masked')
            ->where('devices.0.token_masked', fn ($token) => str_contains($token, '...'))
        );
    }

    public function test_mobile_login_removes_previous_token_for_same_device(): void
    {
        $user = User::factory()->create([
            'password' => Hash::make('password123'),
        ]);

        $passportService = app(\App\Services\SubscriptionService::class);
        $passportService->createPassportToken($user, 'Samsung SM-A165F');

        $this->assertCount(1, $user->tokens);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => $user->email,
            'password' => 'password123',
            'device_name' => 'Samsung SM-A165F',
        ]);

        $response->assertOk();
        // After login, previous token for Samsung SM-A165F is pruned, exactly 1 active token exists
        $this->assertCount(1, $user->fresh()->tokens);
    }
}
