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
        Schema::create('classes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('course_name');
            $table->string('teacher_name')->nullable();
            $table->string('teacher_contact')->nullable();
            $table->decimal('credit_hours', 4, 1)->nullable();
            $table->decimal('ects', 4, 1)->nullable();
            $table->timestamps();

            $table->index(['user_id', 'course_name']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('classes');
    }
};
