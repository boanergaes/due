<?php

namespace Database\Seeders;

use App\Enums\SubscriptionTier;
use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     * Only creates a base user; no default classes or assignments are randomly generated.
     */
    public function run(): void
    {
        // Demo Student (Free tier)
        User::firstOrCreate(
            ['email' => 'student@due.local'],
            [
                'name' => 'Demo Student',
                'password' => bcrypt('password'),
                'appearance' => 'dark',
                'role' => UserRole::Student,
                'subscription_tier' => SubscriptionTier::Free,
            ]
        );

        // Super Administrator
        User::firstOrCreate(
            ['email' => 'admin@due.local'],
            [
                'name' => 'Super Administrator',
                'password' => bcrypt('password'),
                'appearance' => 'dark',
                'role' => UserRole::SuperAdmin,
                'subscription_tier' => SubscriptionTier::Premium,
            ]
        );
    }
}
