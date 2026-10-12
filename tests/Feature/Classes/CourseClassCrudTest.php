<?php

namespace Tests\Feature\Classes;

use App\Models\Assignment;
use App\Models\CourseClass;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CourseClassCrudTest extends TestCase
{
    use RefreshDatabase;

    public function test_guests_cannot_access_classes_pages(): void
    {
        $class = CourseClass::factory()->create([
            'user_id' => User::factory()->create()->id,
            'course_name' => 'Algorithms',
        ]);

        $this->get(route('classes.index'))->assertRedirect(route('login'));
        $this->get(route('classes.create'))->assertRedirect(route('login'));
        $this->post(route('classes.store'), ['course_name' => 'Math'])->assertRedirect(route('login'));
        $this->get(route('classes.show', $class))->assertRedirect(route('login'));
        $this->get(route('classes.edit', $class))->assertRedirect(route('login'));
        $this->put(route('classes.update', $class), ['course_name' => 'Updated'])->assertRedirect(route('login'));
        $this->delete(route('classes.destroy', $class))->assertRedirect(route('login'));
    }

    public function test_user_can_view_classes_index(): void
    {
        $user = User::factory()->create();
        CourseClass::factory()->count(3)->create([
            'user_id' => $user->id,
            'course_name' => 'CS101',
        ]);

        $response = $this->actingAs($user)->get(route('classes.index'));

        $response->assertOk();
    }

    public function test_user_can_create_a_class(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)->post(route('classes.store'), [
            'course_name' => 'Operating Systems',
            'teacher_name' => 'Dr. Andrew Tanenbaum',
            'teacher_contact' => 'tanenbaum@minix.org',
            'credit_hours' => 4,
            'ects' => 6.5,
        ]);

        $response->assertRedirect(route('classes.index'));
        $this->assertDatabaseHas('classes', [
            'user_id' => $user->id,
            'course_name' => 'Operating Systems',
            'teacher_name' => 'Dr. Andrew Tanenbaum',
            'credit_hours' => 4,
        ]);
    }

    public function test_creating_class_requires_course_name(): void
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)->post(route('classes.store'), [
            'course_name' => '',
        ]);

        $response->assertSessionHasErrors(['course_name']);
        $this->assertDatabaseCount('classes', 0);
    }

    public function test_user_can_view_their_class_details(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create([
            'user_id' => $user->id,
            'course_name' => 'Database Systems',
        ]);

        $response = $this->actingAs($user)->get(route('classes.show', $class));

        $response->assertOk();
    }

    public function test_user_cannot_view_another_users_class(): void
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        $class = CourseClass::factory()->create([
            'user_id' => $user1->id,
            'course_name' => 'Private Course',
        ]);

        $response = $this->actingAs($user2)->get(route('classes.show', $class));

        $response->assertForbidden();
    }

    public function test_user_can_update_their_class(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create([
            'user_id' => $user->id,
            'course_name' => 'Original Name',
        ]);

        $response = $this->actingAs($user)->put(route('classes.update', $class), [
            'course_name' => 'Updated Name',
            'teacher_name' => 'Prof. Turing',
            'credit_hours' => 5,
        ]);

        $response->assertRedirect(route('classes.index'));
        $this->assertDatabaseHas('classes', [
            'id' => $class->id,
            'course_name' => 'Updated Name',
            'teacher_name' => 'Prof. Turing',
        ]);
    }

    public function test_user_cannot_update_another_users_class(): void
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        $class = CourseClass::factory()->create([
            'user_id' => $user1->id,
            'course_name' => 'Secret Class',
        ]);

        $response = $this->actingAs($user2)->put(route('classes.update', $class), [
            'course_name' => 'Hacked Name',
        ]);

        $response->assertForbidden();
        $this->assertDatabaseHas('classes', [
            'id' => $class->id,
            'course_name' => 'Secret Class',
        ]);
    }

    public function test_user_can_delete_class_without_assignments(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create([
            'user_id' => $user->id,
            'course_name' => 'Empty Class',
        ]);

        $response = $this->actingAs($user)->delete(route('classes.destroy', $class));

        $response->assertRedirect(route('classes.index'));
        $this->assertDatabaseMissing('classes', [
            'id' => $class->id,
        ]);
    }

    public function test_user_cannot_delete_class_with_existing_assignments(): void
    {
        $user = User::factory()->create();
        $class = CourseClass::factory()->create([
            'user_id' => $user->id,
            'course_name' => 'Class With Homework',
        ]);

        Assignment::factory()->create([
            'user_id' => $user->id,
            'class_id' => $class->id,
            'title' => 'Project 1',
            'deadline' => now()->addDays(5),
        ]);

        $response = $this->actingAs($user)->delete(route('classes.destroy', $class));

        $response->assertSessionHasErrors(['delete']);
        $this->assertDatabaseHas('classes', [
            'id' => $class->id,
            'course_name' => 'Class With Homework',
        ]);
    }

    public function test_user_cannot_delete_another_users_class(): void
    {
        $user1 = User::factory()->create();
        $user2 = User::factory()->create();

        $class = CourseClass::factory()->create([
            'user_id' => $user1->id,
            'course_name' => 'User1 Class',
        ]);

        $response = $this->actingAs($user2)->delete(route('classes.destroy', $class));

        $response->assertForbidden();
        $this->assertDatabaseHas('classes', [
            'id' => $class->id,
        ]);
    }
}
