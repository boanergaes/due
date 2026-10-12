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
}
