<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('role')->default('student')->after('appearance');
            $table->string('subscription_tier')->default('free')->after('role');
            $table->timestamp('subscription_expires_at')->nullable()->after('subscription_tier');
            $table->unsignedBigInteger('storage_used_bytes')->default(0)->after('subscription_expires_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'role',
                'subscription_tier',
                'subscription_expires_at',
                'storage_used_bytes',
            ]);
        });
    }
};
