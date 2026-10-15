<?php

use App\Enums\SubscriptionStatus;
use App\Enums\SubscriptionTier;
use App\Enums\UserRole;
use App\Models\CourseClass;
use App\Models\Resource;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Support\Facades\Storage;

beforeEach(function () {
    Storage::fake('public');
});

test('guest accessing admin routes is redirected to admin login', function () {
    $this->get('/admin')->assertRedirect(route('admin.login'));
    $this->get('/admin/dashboard')->assertRedirect(route('admin.login'));
    $this->get('/admin/users')->assertRedirect(route('admin.login'));
    $this->get('/admin/subscriptions')->assertRedirect(route('admin.login'));
    $this->get('/admin/storage')->assertRedirect(route('admin.login'));
});

test('regular student accessing admin routes receives 404 in stealth mode', function () {
    $student = User::factory()->create([
        'role' => UserRole::Student,
    ]);

    $this->actingAs($student)->get('/admin')->assertNotFound();
    $this->actingAs($student)->get('/admin/dashboard')->assertNotFound();
    $this->actingAs($student)->get('/admin/users')->assertNotFound();
    $this->actingAs($student)->get('/admin/subscriptions')->assertNotFound();
    $this->actingAs($student)->get('/admin/storage')->assertNotFound();
    $this->actingAs($student)->get('/admin/login')->assertNotFound();
});

test('unauthenticated user attempting admin login with student credentials receives 404', function () {
    $student = User::factory()->create([
        'email' => 'student.secret@example.com',
        'password' => bcrypt('password123'),
        'role' => UserRole::Student,
    ]);

    $response = $this->post('/admin/login', [
        'email' => 'student.secret@example.com',
        'password' => 'password123',
    ]);

    $response->assertNotFound();
    $this->assertGuest();
});

test('unauthenticated user attempting admin login with invalid password gets validation error', function () {
    $admin = User::factory()->create([
        'email' => 'admin.chief@example.com',
        'password' => bcrypt('supersecret'),
        'role' => UserRole::Admin,
    ]);

    $response = $this->post('/admin/login', [
        'email' => 'admin.chief@example.com',
        'password' => 'wrongpassword',
    ]);

    $response->assertSessionHasErrors('email');
    $this->assertGuest();
});

test('admin can log in via admin login gate and access dashboard', function () {
    $admin = User::factory()->create([
        'email' => 'admin.gate@example.com',
        'password' => bcrypt('correctpass'),
        'role' => UserRole::Admin,
    ]);

    $response = $this->post('/admin/login', [
        'email' => 'admin.gate@example.com',
        'password' => 'correctpass',
    ]);

    $response->assertRedirect(route('admin.dashboard'));
    $this->assertAuthenticatedAs($admin);

    $this->actingAs($admin)->get('/admin')->assertRedirect(route('admin.dashboard'));
    $this->actingAs($admin)->get('/admin/dashboard')->assertOk();
    $this->actingAs($admin)->get('/admin/users')->assertOk();
    $this->actingAs($admin)->get('/admin/subscriptions')->assertOk();
    $this->actingAs($admin)->get('/admin/storage')->assertOk();
});

test('super admin can override user subscription tier to genius', function () {
    $admin = User::factory()->create(['role' => UserRole::Admin]);
    $student = User::factory()->create([
        'subscription_tier' => SubscriptionTier::Free,
    ]);

    $response = $this->actingAs($admin)->patch("/admin/users/{$student->id}/tier", [
        'tier' => 'premium',
        'interval' => 'monthly',
    ]);

    $response->assertSessionHas('success');

    $student->refresh();
    expect($student->subscription_tier)->toBe(SubscriptionTier::Premium);
    expect($student->subscription_expires_at)->not->toBeNull();

    $activeSub = $student->subscriptions()->where('status', SubscriptionStatus::Active)->first();
    expect($activeSub)->not->toBeNull();
    expect($activeSub->tier)->toBe(SubscriptionTier::Premium);
    expect($activeSub->price)->toBe(9.99);
});

test('super admin can override user subscription tier to free', function () {
    $admin = User::factory()->create(['role' => UserRole::Admin]);
    $student = User::factory()->create([
        'subscription_tier' => SubscriptionTier::Premium,
        'subscription_expires_at' => now()->addMonth(),
    ]);

    Subscription::create([
        'user_id' => $student->id,
        'tier' => SubscriptionTier::Premium,
        'status' => SubscriptionStatus::Active,
        'price' => 9.99,
        'interval' => 'monthly',
        'card_brand' => 'visa',
        'card_last_four' => '4242',
        'mock_transaction_id' => 'mock_init_123',
        'starts_at' => now(),
    ]);

    $response = $this->actingAs($admin)->patch("/admin/users/{$student->id}/tier", [
        'tier' => 'free',
    ]);

    $response->assertSessionHas('success');

    $student->refresh();
    expect($student->subscription_tier)->toBe(SubscriptionTier::Free);
    expect($student->subscription_expires_at)->toBeNull();

    $activeSub = $student->subscriptions()->where('status', SubscriptionStatus::Active)->first();
    expect($activeSub)->toBeNull();
});

test('admin can promote student to admin', function () {
    $admin = User::factory()->create(['role' => UserRole::Admin]);
    $student = User::factory()->create(['role' => UserRole::Student]);

    $response = $this->actingAs($admin)->patch("/admin/users/{$student->id}/role", [
        'role' => 'admin',
    ]);

    $response->assertSessionHas('success');

    $student->refresh();
    expect($student->role)->toBe(UserRole::Admin);
});

test('admin cannot demote the only remaining admin', function () {
    User::where('role', UserRole::Admin)->delete();

    $soleAdmin = User::factory()->create([
        'role' => UserRole::Admin,
    ]);

    $response = $this->actingAs($soleAdmin)->patch("/admin/users/{$soleAdmin->id}/role", [
        'role' => 'student',
    ]);

    $response->assertSessionHas('error');

    $soleAdmin->refresh();
    expect($soleAdmin->role)->toBe(UserRole::Admin);
});

test('super admin can administratively purge an uploaded resource and recover user quota', function () {
    $admin = User::factory()->create(['role' => UserRole::Admin]);
    $student = User::factory()->create(['storage_used_bytes' => 2048]);
    $class = CourseClass::factory()->create([
        'user_id' => $student->id,
        'course_name' => 'Data Structures',
    ]);

    $filePath = 'resources/classes/'.$class->id.'/test-purge.pdf';
    Storage::disk('public')->put($filePath, 'purgeable content');

    $resource = Resource::create([
        'user_id' => $student->id,
        'resourceable_type' => 'class',
        'resourceable_id' => $class->id,
        'title' => 'Purgeable Lecture Slides',
        'file_name' => 'test-purge.pdf',
        'file_path' => $filePath,
        'mime_type' => 'application/pdf',
        'file_size_bytes' => 2048,
    ]);

    $response = $this->actingAs($admin)->delete("/admin/resources/{$resource->id}");
    $response->assertSessionHas('success');

    $this->assertDatabaseMissing('resources', ['id' => $resource->id]);
    Storage::disk('public')->assertMissing($filePath);

    $student->refresh();
    expect($student->storage_used_bytes)->toBe(0);
});

test('super admin can log out from the administrative session', function () {
    $admin = User::factory()->create(['role' => UserRole::Admin]);

    $response = $this->actingAs($admin)->post('/admin/logout');
    $response->assertRedirect('/');

    $this->assertGuest();
});
