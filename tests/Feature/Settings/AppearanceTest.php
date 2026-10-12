<?php

namespace Tests\Feature\Settings;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AppearanceTest extends TestCase
{
    use RefreshDatabase;

    public function test_appearance_settings_page_can_be_rendered(): void
    {
        $user = User::factory()->create([
            'appearance' => 'dark',
        ]);

        $response = $this
            ->actingAs($user)
            ->get(route('appearance.edit'));

        $response->assertOk();
    }

    public function test_guest_cannot_access_appearance_settings_page(): void
    {
        $response = $this->get(route('appearance.edit'));

        $response->assertRedirect(route('login'));
    }

    public function test_user_can_update_and_persist_appearance_preference_in_database(): void
    {
        $user = User::factory()->create([
            'appearance' => 'dark',
        ]);

        $response = $this
            ->actingAs($user)
            ->patch(route('appearance.update'), [
                'appearance' => 'light',
            ]);

        $response
            ->assertSessionHasNoErrors()
            ->assertRedirect();

        $this->assertSame('light', $user->fresh()->appearance);
        $response->assertPlainCookie('appearance', 'light');
    }

    public function test_user_can_select_system_theme_and_persist_it(): void
    {
        $user = User::factory()->create([
            'appearance' => 'dark',
        ]);

        $response = $this
            ->actingAs($user)
            ->patch(route('appearance.update'), [
                'appearance' => 'system',
            ]);

        $response->assertSessionHasNoErrors();
        $this->assertSame('system', $user->fresh()->appearance);
        $response->assertPlainCookie('appearance', 'system');
    }

    public function test_invalid_appearance_value_is_rejected_by_validation(): void
    {
        $user = User::factory()->create([
            'appearance' => 'dark',
        ]);

        $response = $this
            ->actingAs($user)
            ->patch(route('appearance.update'), [
                'appearance' => 'neon_green',
            ]);

        $response->assertSessionHasErrors('appearance');
        $this->assertSame('dark', $user->fresh()->appearance);
    }

    public function test_appearance_is_shared_in_inertia_props_and_matches_database(): void
    {
        $user = User::factory()->create([
            'appearance' => 'light',
        ]);

        $response = $this
            ->actingAs($user)
            ->get(route('dashboard'));

        $response->assertOk();
        $response->assertInertia(fn ($page) => $page
            ->where('appearance', 'light')
            ->where('auth.user.appearance', 'light')
        );
    }
}
