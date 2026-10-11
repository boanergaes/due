# Due — Academic Assignment & Coursework Tracker

A focused, modern coursework and assignment tracking application built with **Laravel 13**, **React 19**, **Inertia.js 3**, and **MySQL 8**. Engineered with an architectural, edgy aesthetic inspired by [laravel.com](https://laravel.com/) featuring zero corner radius (`rounded-none`) and a default dark theme.

---

## 🚀 Quick Start Guide

### 1. Prerequisites
- **PHP:** 8.3 or higher (using PHP 8.5 via Herd-lite)
- **Composer:** 2.8+
- **Node.js:** 20+ & npm
- **Docker & Docker Compose:** For running MySQL

### 2. Environment & Database Setup

1. **Start the MySQL container:**
   ```bash
   docker compose up -d
   ```
   *(This starts MySQL 8 on port `3306` with database `due` and persistent volume storage).*

2. **Verify `.env` configuration:**
   ```env
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=due
   DB_USERNAME=root
   DB_PASSWORD=password
   ```

3. **Run database migrations:**
   ```bash
   php artisan migrate
   ```

4. **Seed the base user account (Optional):**
   ```bash
   php artisan db:seed
   ```
   *(Creates a base user `student@due.local` with password `password`).*

### 3. Starting the Development Servers

1. **Backend Server (Laravel):**
   ```bash
   php artisan serve
   ```
   Your application will be live at: **http://127.0.0.1:8000**

2. **Frontend Assets (Vite):**
   ```bash
   npm run dev
   ```
   *(Or run `npm run build` to compile production assets).*

---

## 🔍 How to Inspect the Database (Prisma Studio Equivalents)

If you are accustomed to `npx prisma studio`, here are the easiest ways to view and interact with your MySQL database:

### Option A: Built-in Terminal Inspection (Zero Setup)

- **View database summary, open connections, and table list:**
  ```bash
  php artisan db:show
  ```

- **Inspect table schema and row counts:**
  ```bash
  php artisan db:table classes
  php artisan db:table assignments
  ```

- **Interactive Model REPL (`php artisan tinker`):**
  A live PHP interactive shell (similar to the Node REPL) to query Eloquent models:
  ```bash
  php artisan tinker
  ```
  ```php
  // View all users
  User::all();

  // Inspect courses with their assignments
  CourseClass::with('assignments')->get();

  // Create an assignment directly
  Assignment::create([
      'user_id' => 1,
      'class_id' => 1,
      'title' => 'Sample Task',
      'deadline' => now()->addDays(2),
  ]);

  // Exit the shell
  exit;
  ```

### Option B: Free GUI Desktop Apps (Closest to Prisma Studio)
You can connect any visual database manager to your local MySQL instance:

- **[Beekeeper Studio](https://www.beekeeperstudio.io/)** (Open source, sleek, modern — feels very similar to Prisma Studio)
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
| **Reset & seed** | `php artisan migrate:fresh --seed` | `prisma migrate reset` + seed | Drops all tables, re-migrates, and seeds the base user. |
| **Migration status** | `php artisan migrate:status` | `npx prisma migrate status` | Shows which migrations have run and their batch IDs. |
| **Create migration** | `php artisan make:migration create_xxx_table` | Schema file change | Scaffolds a new migration file in `database/migrations/`. |

### Development, Routing & Testing
| Task | Command | Description |
| :--- | :--- | :--- |
| **Start server** | `php artisan serve` | Starts the local PHP development server on port 8000. |
| **List routes** | `php artisan route:list` | Displays all registered URLs, HTTP methods, and actions. |
| **Run tests** | `php artisan test` | Executes the Pest automated test suite. |
| **Format code** | `vendor/bin/pint` | Fixes PHP code style according to Laravel conventions. |
| **Check code style** | `vendor/bin/pint --test` | Verifies code style without modifying files. |
| **TypeScript check** | `npm run types:check` | Runs `tsc --noEmit` to verify React/TypeScript types. |
| **Build frontend** | `npm run build` | Builds and bundles frontend assets with Vite. |

### Code Generators (`make:`)
- **Create Model:** `php artisan make:model CourseClass`
- **Create Model + Migration + Controller:** `php artisan make:model CourseClass -mc`
- **Create Form Request:** `php artisan make:request StoreClassRequest`
- **Create Policy:** `php artisan make:policy ClassPolicy --model=CourseClass`
- **Create Factory:** `php artisan make:factory CourseClassFactory`

---

## 📐 Project Architecture & Design Rules

1. **Zero Corner Radius Rule:**
   - Every button, input, card, modal, badge, and container strictly uses `border-radius: 0px` (`rounded-none`).
   - The design is crisp, architectural, and sharp.

2. **Default Dark Theme:**
   - Dark mode is enabled by default for all new visitors.
   - All colors and surfaces are driven by semantic CSS variables defined in [app.css](file:///home/zeamanuel/projects/zainx/due/resources/css/app.css) and mapped to Tailwind tokens (`bg-background`, `text-foreground`, `border-border`, `bg-card`, `bg-primary`, etc.).

3. **Database Relationships & Integrity:**
   - **`classes`:** Belongs to `users` (`cascadeOnDelete`).
   - **`assignments`:** Belongs to `users` (`cascadeOnDelete`) and `classes` with **`restrictOnDelete()`**. Deleting a class is restricted while assignments exist to protect academic data.
   - **`assignment_notes`:** Belongs to `assignments` (`cascadeOnDelete`).

4. **Testing Suite:**
   - Automated tests are written using **Pest 5** under `tests/Feature/`.
   - Run tests anytime with `php artisan test`.
