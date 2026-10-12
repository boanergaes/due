<?php

namespace Database\Seeders;

use App\Enums\AssignmentStatus;
use App\Models\Assignment;
use App\Models\AssignmentNote;
use App\Models\CourseClass;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;

class DemoDataSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Run the database seeds with rich demo data for demonstration and testing.
     */
    public function run(): void
    {
        $user = User::firstOrCreate(
            ['email' => 'student@due.local'],
            [
                'name' => 'Demo Student',
                'password' => bcrypt('password'),
                'email_verified_at' => now(),
            ]
        );

        // 1. Create Academic Courses
        $distSystems = CourseClass::firstOrCreate(
            ['user_id' => $user->id, 'course_name' => 'CS 401: Distributed Systems'],
            [
                'teacher_name' => 'Prof. Andrew Tanenbaum',
                'teacher_contact' => 'atanenbaum@university.edu',
                'credit_hours' => 4,
                'ects' => 6,
            ]
        );

        $dbSystems = CourseClass::firstOrCreate(
            ['user_id' => $user->id, 'course_name' => 'CS 320: Database Architecture'],
            [
                'teacher_name' => 'Dr. Michael Stonebraker',
                'teacher_contact' => 'mstonebraker@university.edu',
                'credit_hours' => 3,
                'ects' => 5,
            ]
        );

        $softwareEng = CourseClass::firstOrCreate(
            ['user_id' => $user->id, 'course_name' => 'SE 350: Software Engineering & Agile'],
            [
                'teacher_name' => 'Dr. Martin Fowler',
                'teacher_contact' => 'mfowler@university.edu',
                'credit_hours' => 3,
                'ects' => 5,
            ]
        );

        $hci = CourseClass::firstOrCreate(
            ['user_id' => $user->id, 'course_name' => 'HCI 210: Human-Computer Interaction'],
            [
                'teacher_name' => 'Dr. Don Norman',
                'teacher_contact' => 'dnorman@university.edu',
                'credit_hours' => 2,
                'ects' => 4,
            ]
        );

        // 2. Create Assignments with various statuses and realistic urgency deadlines
        $now = Carbon::now();

        // A. Completed on time
        $assignment1 = Assignment::create([
            'user_id' => $user->id,
            'class_id' => $distSystems->id,
            'title' => 'Lab 1: Raft Consensus Protocol Implementation',
            'description' => 'Implement leader election, log replication, and RPC heartbeat mechanisms in Go.',
            'status' => AssignmentStatus::Completed,
            'deadline' => $now->copy()->subDays(5),
            'completed_at' => $now->copy()->subDays(6), // completed before deadline
        ]);

        AssignmentNote::create([
            'assignment_id' => $assignment1->id,
            'content' => 'Passed all 50 concurrent leader election unit tests. Submitted via GitHub Classroom.',
        ]);

        // B. Completed
        $assignment2 = Assignment::create([
            'user_id' => $user->id,
            'class_id' => $dbSystems->id,
            'title' => 'B-Tree Indexing & Buffer Pool Performance Benchmarking',
            'description' => 'Compare read throughput between B+ Trees and LSM Trees under high write concurrency.',
            'status' => AssignmentStatus::Completed,
            'deadline' => $now->copy()->subDays(2),
            'completed_at' => $now->copy()->subDays(2)->subHours(3),
        ]);

        AssignmentNote::create([
            'assignment_id' => $assignment2->id,
            'content' => 'Buffer pool replacement strategy: Clock sweep algorithm gave best cache hit ratio.',
        ]);

        // C. Due Today (High Urgency)
        $assignment3 = Assignment::create([
            'user_id' => $user->id,
            'class_id' => $hci->id,
            'title' => 'User Persona & Interactive Prototype Submission',
            'description' => 'Deliver Figma component library and interactive user journey map for the design critique session.',
            'status' => AssignmentStatus::Pending,
            'deadline' => $now->copy()->addHours(6),
        ]);

        AssignmentNote::create([
            'assignment_id' => $assignment3->id,
            'content' => 'Check contrast ratios against WCAG Level AA guidelines before exporting screens.',
        ]);

        // D. Due Soon (< 48 hours)
        $assignment4 = Assignment::create([
            'user_id' => $user->id,
            'class_id' => $softwareEng->id,
            'title' => 'Sprint 2 Retrospective & Architecture Review Document',
            'description' => 'Summarize velocity chart, burndown metrics, and architectural decisions made for the sprint.',
            'status' => AssignmentStatus::InProgress,
            'deadline' => $now->copy()->addHours(30),
        ]);

        AssignmentNote::create([
            'assignment_id' => $assignment4->id,
            'content' => 'Include team notes on Docker containerization bottleneck from sprint day 4.',
        ]);

        // E. Upcoming Future
        $assignment5 = Assignment::create([
            'user_id' => $user->id,
            'class_id' => $dbSystems->id,
            'title' => 'Relational Query Optimizer Cost Model',
            'description' => 'Build a cost-based query planner calculating estimated disk I/O and CPU costs for nested loop vs hash joins.',
            'status' => AssignmentStatus::InProgress,
            'deadline' => $now->copy()->addDays(5),
        ]);

        // F. Upcoming Future
        $assignment6 = Assignment::create([
            'user_id' => $user->id,
            'class_id' => $distSystems->id,
            'title' => 'Lab 2: Distributed Key-Value Store with Sharding',
            'description' => 'Integrate consistent hashing and two-phase commit transaction coordinator across 5 nodes.',
            'status' => AssignmentStatus::Pending,
            'deadline' => $now->copy()->addDays(12),
        ]);

        // G. Overdue Assignment (Requiring attention)
        $assignment7 = Assignment::create([
            'user_id' => $user->id,
            'class_id' => $softwareEng->id,
            'title' => 'CI/CD Pipeline Configuration with GitHub Actions',
            'description' => 'Automate test execution, static analysis with PHPStan, and Docker image publishing on git push.',
            'status' => AssignmentStatus::InProgress,
            'deadline' => $now->copy()->subHours(18),
        ]);

        AssignmentNote::create([
            'assignment_id' => $assignment7->id,
            'content' => 'Need to request extension from Dr. Fowler due to runner concurrency limits.',
        ]);
    }
}
