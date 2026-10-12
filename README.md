# Due — Academic Assignment & Coursework Tracker

A focused, modern coursework and assignment tracking application built with **Laravel 13**, **React 19**, **Inertia.js 3**, and **MySQL 8**. Engineered with an architectural, edgy aesthetic inspired by [laravel.com](https://laravel.com/) featuring a strict zero corner radius (`rounded-none`) design system and a default dark theme.

---

## 🚀 Quick Start Guide

### 1. Prerequisites
- **PHP:** 8.3 or higher (PHP 8.5 via Herd-lite / CLI)
- **Composer:** 2.8+
- **Node.js:** 20+ & npm
- **Docker & Docker Compose:** For running MySQL 8

### 2. Environment & Database Setup

1. **Start the MySQL container:**
   ```bash
   docker compose up -d
   ```
   *(Starts MySQL 8 on `127.0.0.1:3306` with database `due` and persistent volume storage).*

2. **Verify `.env` configuration:**
   ```env
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=due
   DB_USERNAME=root
   DB_PASSWORD=password
   SESSION_DRIVER=database
   ```

3. **Run database migrations:**
   ```bash
   php artisan migrate
   ```

4. **Seed the database:**
   - **Option A: Base User Only**
     ```bash
     php artisan db:seed
     ```
     *(Creates `student@due.local` with password `password` and an empty academic catalog).*
   - **Option B: Realistic Demo Coursework & Data (Recommended for Testing & Demos)**
     ```bash
     php artisan db:seed --class=DemoDataSeeder
     ```
     *(Creates `student@due.local` with 4 realistic courses, 7 assignments covering all urgency states — overdue, due today, due soon, upcoming, completed — and associated notes).*

### 3. Starting the Development Servers

1. **Backend Server (Laravel):**
   ```bash
   php artisan serve
   ```
   Application will be live at: **http://127.0.0.1:8000**

2. **Frontend Assets (Vite Development Server):**
   ```bash
   npm run dev
   ```
   *(Or compile for production with `npm run build`).*

---

## 🏛️ Application Architecture

### 1. Web Application: Laravel 13 + React 19 + Inertia.js 3
- **Monolithic Clarity with SPA Feel:** Rather than building a separate REST/GraphQL client with duplicate routing, client-side state managers, and mock endpoints, **Inertia.js** bridges Laravel and React.
- **Data Flow:**
  - Standard browser requests load the root HTML template (`resources/views/app.blade.php`).
  - Subsequent transitions are performed via Inertia `X-Inertia` AJAX requests, which return JSON containing the component name and controller page props.
  - React renders pages smoothly without full browser reloads.
- **Authentication & Security:**
  - Session-based cookie authentication backed by Laravel Fortify.
  - CSRF protection on all non-GET requests (`X-XSRF-TOKEN` automatically handled by Axios/Inertia).
  - Explicit server-side ownership enforcement: all database queries and mutations are scoped to `$request->user()->id` with Laravel Policies.

### 2. Future Flutter Client Architecture (Mobile App)
When introducing a native **Flutter** mobile client in the future, the existing backend cleanly supports mobile consumption without restructuring:
- **Authentication with Laravel Sanctum:**
  - Mobile clients will authenticate via a dedicated `/api/v1/login` endpoint issuing a personal access token (`Bearer <token>`).
  - The token is stored securely in Flutter's `flutter_secure_storage` (iOS Keychain / Android Keystore).
  - Sanctum's `auth:sanctum` middleware validates the Bearer token on every mobile API request.
- **Shared Business Logic Layer:**
  - Business rules—specifically **deadline calculations, urgency levels, and time zone boundary checks**—are encapsulated in the dedicated service class `App\Services\DeadlineUrgencyService`.
  - Both the Inertia web controllers (`DashboardController`, `AssignmentController`) and future REST API controllers (`Api\V1\AssignmentController`) call this identical service layer, guaranteeing that mobile and web clients never produce differing urgency calculations or status evaluations.

```
                  ┌────────────────────────────────────────┐
                  │          Laravel 13 Backend            │
                  │                                        │
                  │  ┌──────────────────────────────────┐  │
                  │  │     DeadlineUrgencyService       │  │
                  │  │  (Urgency & Deadline Logic)      │  │
                  │  └───────────────┬──────────────────┘  │
                  │                  │                     │
                  │       ┌──────────┴──────────┐          │
                  │       ▼                     ▼          │
                  │  Inertia Web          Sanctum REST     │
                  │  Controllers          API Controllers  │
                  └───────┬─────────────────────┬──────────┘
                          │ (Session Auth)      │ (Bearer Tokens)
                          │ (X-Inertia Props)   │ (JSON Payloads)
                          ▼                     ▼
                  ┌───────────────┐     ┌───────────────┐
                  │ React 19 Web  │     │ Future Flutter│
                  │ (Inertia SPA) │     │ Mobile Client │
                  └───────────────┘     └───────────────┘
```

---

## ⚡ The N+1 Query Problem: Diagnosis & Verification

### 1. What is the N+1 Query Problem?
The **N+1 query problem** happens when an ORM executes 1 query to fetch a parent record set (e.g. 50 assignments), and then executes an additional separate database query for **every individual parent record** to fetch a related model (e.g. the course each assignment belongs to). For $N = 50$ assignments, the application issues $1 + 50 = 51$ queries instead of 2. On high-traffic pages, this rapidly saturates database connection pools and introduces severe latency.

### 2. Where Did It Occur in Due?
In both the **Assignments List** (`/assignments`) and the **Dashboard Upcoming Feed** (`/dashboard`), each assignment displays its parent course's name:
```tsx
{assignment.course_class ? (
    <span>{assignment.course_class.course_name}</span>
) : null}
```
If assignments were queried naively via:
```php
// NAIVE IMPLEMENTATION (Triggers N+1):
$assignments = Assignment::where('user_id', $user->id)->get();
```
Accessing `$assignment->course_class` in PHP or serializing it for Inertia causes Eloquent to issue a separate `SELECT * FROM classes WHERE id = ?` query for every single assignment in the collection.

### 3. The Fix Applied
We resolved this using Eloquent's eager loading mechanisms:
1. **Eager Loading Foreign Relations (`with`):**
   ```php
   // OPTIMIZED IMPLEMENTATION:
   $assignments = Assignment::where('user_id', $user->id)
       ->with(['course_class'])
       ->paginate(15);
   ```
   Eloquent compiles this into precisely **two queries**, regardless of whether 10 or 1,000 assignments are retrieved:
   ```sql
   -- Query 1: Fetch paginated assignments
   SELECT * FROM `assignments` WHERE `user_id` = 1 ORDER BY `deadline` ASC LIMIT 15;

   -- Query 2: Eager load all referenced classes in a single IN clause
   SELECT * FROM `classes` WHERE `id` IN (1, 2, 4);
   ```

2. **Aggregates Without Loading (`withCount`):**
   On the courses index (`/classes`), to display the number of assignments per class without hydrating every assignment model:
   ```php
   $classes = CourseClass::where('user_id', $user->id)
       ->withCount('assignments')
       ->paginate(15);
   ```
   This executes a performant subquery (`SELECT COUNT(*) FROM assignments...`) inside the primary query.

### 4. How Was It Verified?
We wrote an automated feature test in [tests/Feature/Dashboard/DashboardQueryCountTest.php](file:///home/zeamanuel/projects/zainx/due/tests/Feature/Dashboard/DashboardQueryCountTest.php) that enables Laravel's query logger (`DB::enableQueryLog()`) and proves $O(1)$ query complexity:
```php
test('dashboard query count does not grow linearly with assignment count', function () {
    // 1. Measure query count with 3 assignments across 3 classes
    DB::flushQueryLog();
    $responseA = $this->actingAs($user)->get(route('dashboard'));
    $queryCountA = count(DB::getQueryLog());

    // 2. Add 15 MORE assignments across new classes
    Assignment::factory()->count(15)->create(['user_id' => $user->id]);

    // 3. Measure query count again
    DB::flushQueryLog();
    $responseB = $this->actingAs($user)->get(route('dashboard'));
    $queryCountB = count(DB::getQueryLog());

    // Query count must remain completely identical
    expect($queryCountB)->toBe($queryCountA);
});
```
This test passes and guarantees N+1 regressions cannot enter the codebase.

---

## 🔍 How to Inspect the Database (Prisma Studio Equivalents)

If you are accustomed to `npx prisma studio`, here are the easiest ways to view and interact with your MySQL database:

### Option A: Built-in Terminal Inspection (Zero Setup)

- **View database summary, open connections, and table list:**
  ```bash
  php artisan db:show
  ```

- **Inspect table schema, row counts, and indexes:**
  ```bash
  php artisan db:table classes
  php artisan db:table assignments
  php artisan db:table assignment_notes
  ```

- **Interactive Model REPL (`php artisan tinker`):**
  A live PHP interactive shell (similar to the Node REPL) to query Eloquent models:
  ```bash
  php artisan tinker
  ```
  ```php
  // View all users
  User::all();

  // Inspect courses with their eager-loaded assignments
  CourseClass::with('assignments')->get();

  // Inspect urgency for an assignment
  $assignment = Assignment::first();
  $assignment->urgency; // Returns ['label' => '...', 'variant' => '...']

  exit;
  ```

### Option B: Free GUI Desktop Apps (Closest to Prisma Studio)
Connect any visual database manager to your local Docker MySQL instance:
- **[Beekeeper Studio](https://www.beekeeperstudio.io/)** (Open source, sleek, modern — very similar to Prisma Studio)
- **[TablePlus](https://tableplus.com/)** (Lightweight, popular among Laravel developers)
- **[DBeaver](https://dbeaver.io/)** (Universal open-source DB client)

**Connection Credentials:**
| Setting | Value |
| :--- | :--- |
| **Host** | `127.0.0.1` |
| **Port** | `3306` |
| **User** | `root` |
| **Password** | `password` |
| **Database** | `due` |

---

## 🛠️ Essential Terminal Commands Cheat Sheet

### Database & Migrations
| Task | Laravel Command | Prisma Analogy | What it does |
| :--- | :--- | :--- | :--- |
| **Run migrations** | `php artisan migrate` | `npx prisma migrate dev` | Applies new migrations to the database. |
| **Reset database** | `php artisan migrate:fresh` | `npx prisma migrate reset` | Drops all tables and re-runs all migrations. |
| **Reset & seed demo** | `php artisan migrate:fresh --seed` | `prisma migrate reset` + seed | Resets database and seeds base user. |
| **Seed rich demo data** | `php artisan db:seed --class=DemoDataSeeder` | Custom seed script | Populates courses, assignments, and notes. |
| **Migration status** | `php artisan migrate:status` | `npx prisma migrate status` | Shows which migrations have run. |

### Development, Quality & Testing
| Task | Command | Description |
| :--- | :--- | :--- |
| **Start server** | `php artisan serve` | Starts local PHP development server on port 8000. |
| **List routes** | `php artisan route:list` | Displays all registered URLs, HTTP methods, and actions. |
| **Run tests** | `php artisan test` | Executes the Pest automated test suite (108 tests). |
| **Format code** | `vendor/bin/pint` | Fixes PHP code style according to Laravel conventions. |
| **Check code style** | `vendor/bin/pint --test` | Verifies code style without modifying files. |
| **TypeScript check** | `npm run types:check` | Runs `tsc --noEmit` to verify React/TypeScript types. |
| **Build frontend** | `npm run build` | Builds and bundles frontend assets with Vite. |

---

## 📐 Project Design System & Integrity Rules

1. **Strict Zero Corner Radius Rule:**
   - Every element—buttons, inputs, cards, tables, badges, modals, tooltips, and avatars—strictly uses `border-radius: 0px` (`rounded-none`).
   - Reinforced at root level via `*, *::before, *::after { border-radius: 0px !important; }` in [resources/css/app.css](file:///home/zeamanuel/projects/zainx/due/resources/css/app.css).

2. **Default Dark Theme & Database-Backed Persistence (Zero Local Storage):**
   - Default theme is dark for all visitors, inspired by the high-contrast aesthetic of `laravel.com`.
   - Palette powered by semantic CSS variables (`--background`, `--foreground`, `--border`, `--card`, `--primary`, `--muted`).
   - Monospace typography used for all timestamps, credit units, ECTS tags, and status badges.
   - **Zero LocalStorage:** The user's theme preference (`light`, `dark`, `system`) is persisted directly in the MySQL database (`users.appearance`) and synchronized via cookie for instant server-side rendering. User preferences remain consistent across different computers, browsers, and mobile devices without relying on `localStorage`.

3. **Database Integrity & Foreign Keys:**
   - **`classes`:** Belongs to `users` (`cascadeOnDelete`).
   - **`assignments`:** Belongs to `users` (`cascadeOnDelete`) and `classes` with **`restrictOnDelete()`**. Deleting a course that has registered assignments is blocked by the database and controller to prevent accidental coursework loss.
   - **`assignment_notes`:** Belongs to `assignments` (`cascadeOnDelete`).

4. **Automated Testing Suite:**
   - **114 tests** written with Pest 5 under `tests/Feature/` and `tests/Unit/`.
   - Covers guest protection, authenticated CRUD, ownership enforcement, deadline calculations, notes CRUD, session management, theme persistence, and query count assertions.
