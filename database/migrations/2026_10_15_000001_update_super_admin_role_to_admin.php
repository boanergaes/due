<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        DB::table('users')
            ->where('role', 'super_admin')
            ->update(['role' => 'admin']);

        DB::table('users')
            ->where('name', 'Super Administrator')
            ->update(['name' => 'Administrator']);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::table('users')
            ->where('role', 'admin')
            ->update(['role' => 'super_admin']);

        DB::table('users')
            ->where('name', 'Administrator')
            ->update(['name' => 'Super Administrator']);
    }
};
