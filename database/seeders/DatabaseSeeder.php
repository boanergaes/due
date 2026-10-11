<?php

namespace Database\Seeders;

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
        User::factory()->create([
            'name' => 'Demo Student',
            'email' => 'student@due.local',
        ]);
    }
}
