# Due — Academic Assignment & Coursework Tracker

[![PHP](https://img.shields.io/badge/PHP-8.3%2B-777BB4?style=flat&logo=php&logoColor=white)](https://www.php.net/)
[![Laravel](https://img.shields.io/badge/Laravel-13-FF2D20?style=flat&logo=laravel&logoColor=white)](https://laravel.com/)
[![React](https://img.shields.io/badge/React-19-61DAFB?style=flat&logo=react&logoColor=black)](https://react.dev/)
[![Inertia.js](https://img.shields.io/badge/Inertia.js-3-9553E9?style=flat&logo=inertia&logoColor=white)](https://inertiajs.com/)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat&logo=flutter&logoColor=white)](https://flutter.dev/)
[![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?style=flat&logo=mysql&logoColor=white)](https://www.mysql.com/)
[![TailwindCSS](https://img.shields.io/badge/Tailwind-CSS-38B2AC?style=flat&logo=tailwind-css&logoColor=white)](https://tailwindcss.com/)
[![Tests](https://img.shields.io/badge/Pest%20Tests-218%20Passed-22C55E?style=flat&logo=pest&logoColor=white)](https://pestphp.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A focused, high-performance coursework and deadline management ecosystem built with **Laravel 13**, **React 19**, **Inertia.js 3**, and **Flutter**. Engineered with an architectural, edgy aesthetic inspired by [laravel.com](https://laravel.com/) featuring a strict zero corner radius (`rounded-none` / `BorderRadius.zero`) design system and database-persisted dark mode by default.

---

## 📑 Table of Contents

- [Overview & Key Features](#-overview--key-features)
- [Application Architecture](#-application-architecture)
- [Technology Stack](#-technology-stack)
- [Project Structure](#-project-structure)
- [Prerequisites](#-prerequisites)
- [Installation & Setup](#-installation--setup)
  - [1. Backend & Database Setup](#1-backend--database-setup)
  - [2. Frontend Web Client](#2-frontend-web-client)
  - [3. Flutter Mobile Client](#3-flutter-mobile-client)
  - [4. Default Demo Accounts](#4-default-demo-accounts)
- [Database Management & Inspection](#-database-management--inspection)
- [Testing & Quality Assurance](#-testing--quality-assurance)
- [Environment Configuration](#-environment-configuration)
- [Design System & UI Guidelines](#-design-system--ui-guidelines)
- [License](#-license)

---

## ✨ Overview & Key Features

### 🎓 Academic Coursework Management
- **Course Catalog**: Organize academic classes with credit hours (CH), European Credit Transfer System (ECTS) weighting, instructor contact info, and linked coursework counts.
- **Accidental Deletion Safeguards**: Database-level foreign key restrictions (`restrictOnDelete`) prevent deleting courses that have active assignments, preventing coursework loss.

### ⏱️ Dynamic Deadline & Urgency Engine
- **Calculated Urgency States**: Coursework is continuously evaluated into 5 distinct urgency categories:
  - `Overdue` (Past deadline, uncompleted)
  - `Due Today` (Due within the current calendar day)
  - `Due Soon` (Due within the next 48 hours)
  - `Upcoming` (Due further in the future)
  - `Completed` (Turned in / finished)
- **Countdown Badges**: Real-time humanized deadline countdowns with high-contrast color indicators.
- **Multi-Factor Filtering**: Instant filtering by course, completion status, and urgency state.

### 📝 Assignment Notes & Study Logs
- Attach structured markdown-friendly study notes, assignment requirements, and checklists directly to each assignment.

### 📁 Cloud Storage & In-App Resource Viewers
- Upload syllabus files, lecture slides, diagrams, and assignment resources (PDF, PNG, JPG, WEBP, TXT).
- In-browser and in-app document viewer, PDF reader, and image lightbox.
- Tier-enforced storage quotas and single-file upload size limits.

### 🤖 Due Copilot (Gemini AI Study Tutor)
- Context-aware AI tutoring sidebar and drawer powered by Google Gemini.
- Coursework referencing (`@assignment` and course syllabus context) allowing the AI to tutor on specific problem sets and homework prompts.
- Suggested quick-prompt chips, streaming responses, and markdown code formatting.

### 💳 Tiered Academic Subscriptions
- **Free Tier ($0.00)**: Full coursework tracking, urgency engine, and study notes.
- **Scholar Tier ($4.99/mo or $49.00/yr)**: Unlimited course & assignment file uploads, 500 MB cloud storage quota, in-app document viewers.
- **Genius Tier ($9.99/mo or $99.00/yr)**: Everything in Scholar plus Due Copilot (Gemini AI tutoring) and a 5 GB cloud storage quota.
- Built-in simulated sandbox checkout, plan upgrades, downgrades, and cancellations.

### 🛡️ Super Admin Control Center
- **System Telemetry**: Real-time overview of active students, Monthly Recurring Revenue (MRR), total storage used, and AI interaction metrics.
- **User Management**: Instant search, filter by role (Student / Admin) and tier (Free / Scholar / Genius), role promotion/demotion, and instant subscription tier overrides.

### 📱 Device & Remote Session Management
- Multi-device active session tracking for both browser cookies and mobile API tokens.
- Automatic hardware device detection (e.g. Pixel, Galaxy, iPhone model names).
- Masked token inspection (`...`) and one-click remote session revocation.

---

## 🏛️ Application Architecture

Due is designed around a unified backend architecture serving both an **Inertia.js Single-Page Application (SPA)** for the web and a **RESTful API** for native mobile clients.

```
                                ┌───────────────────────────────────────────────────┐
                                │               Laravel 13 Backend                  │
                                │                                                   │
                                │  ┌─────────────────────────────────────────────┐  │
                                │  │           Shared Service Layer              │  │
                                │  │  • DeadlineUrgencyService                   │  │
                                │  │  • SubscriptionService & Quotas             │  │
                                │  │  • ResourceStorageService                   │  │
                                │  │  • GeminiAiService & Copilot                │  │
                                │  │  • AdminStatsService                        │  │
                                │  └──────────────────────┬──────────────────────┘  │
                                │                         │                         │
                                │        ┌────────────────┴───────────────┐         │
                                │        ▼                                ▼         │
                                │  Inertia Web Controllers        REST API v1       │
                                │  (Cookie / Fortify Auth)        (Bearer Tokens)   │
                                └────────┬────────────────────────────────┬─────────┘
                                         │                                │
                       X-Inertia JSON Props                        JSON Payloads
                                         │                                │
                                         ▼                                ▼
                              ┌──────────────────────┐        ┌───────────────────────┐
                              │  React 19 + Inertia  │        │     Flutter 3.x       │
                              │     Web Frontend     │        │     Mobile Client     │
                              │  (Tailwind, Monorepo)│        │   (iOS, Android, PWA) │
                              └──────────────────────┘        └───────────────────────┘
```

### Architectural Principles

1. **Shared Domain Logic**: All business rules—specifically urgency evaluations, deadline countdowns, storage limits, and feature authorizations—are encapsulated in Laravel Services (`App\Services\*`). Web controllers and mobile API endpoints invoke the identical service layer, guaranteeing 100% parity across web and mobile.
2. **Unified Data Integrity**: Database foreign key constraints enforce strict isolation by user ID (`$request->user()->id`). Deletions cascade where appropriate, but delete operations on parent courses are restricted if child coursework exists.
3. **Dual Authentication Strategy**:
   - **Web Client**: Secure HTTP-only cookies managed by Laravel Fortify with automatic CSRF token verification (`X-XSRF-TOKEN`).
   - **Mobile Client**: Personal API access tokens managed via Laravel Sanctum/Passport (`Bearer <token>`) stored in secure device storage (`flutter_secure_storage`).
4. **Zero Client-Side Theme Desynchronization**: Theme settings (`dark`, `light`, `system`) are saved directly in MySQL (`users.appearance`), synchronized via cookie/profile updates, ensuring consistent cross-device appearance without relying on fragile browser `localStorage`.

---

## 💻 Technology Stack

| Layer | Technology | Purpose |
| :--- | :--- | :--- |
| **Backend Framework** | Laravel 13 (PHP 8.3+) | Routing, Eloquent ORM, Fortify Auth, API endpoints |
| **Frontend Framework** | React 19 + TypeScript | Component-based UI with strong typing |
| **Full-Stack Glue** | Inertia.js 3 | Server-driven routing and state without REST boilerplate |
| **Mobile Client** | Flutter 3.x (Dart) | Cross-platform native mobile app (Android / iOS) |
| **Styling & Design** | Tailwind CSS + Lucide Icons | Zero-radius design system, custom CSS tokens |
| **Database** | MySQL 8.0 | Relational database with strict foreign keys & indexing |
| **AI Integration** | Google Gemini API | Contextual academic tutoring and study assistant |
| **Testing** | Pest 5 & Flutter Test | 218+ PHP feature/unit tests, 30+ Flutter widget tests |
| **Containerization** | Docker & Docker Compose | Local MySQL containerization |

---

## 📂 Project Structure

```
due/
├── app/
│   ├── Enums/                  # SubscriptionTier, UserRole, UrgencyLevel, etc.
│   ├── Http/
│   │   ├── Controllers/        # Inertia Web Controllers (Assignments, Classes, etc.)
│   │   │   ├── Admin/          # Super Admin dashboard & user management
│   │   │   └── Api/V1/         # Mobile REST API endpoints (Auth, Coursework, AI)
│   │   └── Middleware/         # Feature gates, stealth admin mode, subscription checks
│   ├── Models/                 # User, CourseClass, Assignment, Note, Subscription
│   ├── Policies/               # Granular ownership authorization policies
│   └── Services/               # Shared domain logic (Urgency, AI, Storage, Subscriptions)
├── database/
│   ├── factories/              # Model factories for robust testing
│   ├── migrations/             # MySQL schema migrations
│   └── seeders/                # DatabaseSeeder & DemoDataSeeder
├── mobile/                     # Complete Flutter cross-platform mobile client
│   ├── lib/
│   │   ├── config/             # API routes & theme tokens
│   │   ├── models/             # Strongly typed Dart models
│   │   ├── providers/          # State management (Auth, Assignments, Courses, AI)
│   │   ├── screens/            # Mobile views (Dashboard, Courses, Assignments, Settings)
│   │   ├── services/           # ApiClient, DeviceService, Storage
│   │   └── widgets/            # Reusable zero-radius UI components
│   └── test/                   # Comprehensive Flutter widget & integration tests
├── resources/
│   ├── css/                    # Tailwind CSS definitions and zero-radius rule
│   └── js/
│       ├── components/         # Reusable React UI components
│       ├── layouts/            # AppLayout, AdminLayout, SettingsLayout
│       └── pages/              # Inertia page views (Dashboard, Assignments, Admin, etc.)
├── routes/
│   ├── api.php                 # Mobile REST API routes (/api/v1/*)
│   └── web.php                 # Web application routes
└── tests/
    ├── Feature/                # Pest feature tests (Auth, CRUD, Admin, Subscriptions, AI)
    └── Unit/                   # Unit tests for domain calculations
```

---

## ⚙️ Prerequisites

Ensure you have the following installed on your development machine:

- **PHP**: `^8.3` (or PHP 8.4/8.5 via Laravel Herd / CLI)
- **Composer**: `^2.8`
- **Node.js**: `^20.0` & **npm**
- **Docker & Docker Compose**: For local MySQL 8 database
- **Flutter SDK**: `^3.19` (Optional, required only for mobile client development)

---

## 🚀 Installation & Setup

### 1. Backend & Database Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/due.git
   cd due
   ```

2. **Install PHP dependencies:**
   ```bash
   composer install
   ```

3. **Configure Environment File:**
   ```bash
   cp .env.example .env
   php artisan key:generate
   ```

4. **Start the MySQL container via Docker Compose:**
   ```bash
   docker compose up -d
   ```
   *This initializes a MySQL 8 container bound to `127.0.0.1:3306` with database `due` and user `root` (`password: password`).*

5. **Verify database credentials in `.env`:**
   ```env
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=due
   DB_USERNAME=root
   DB_PASSWORD=password
   SESSION_DRIVER=database
   ```

6. **Run migrations:**
   ```bash
   php artisan migrate
   ```

7. **Seed the database:**
   - **Option A: Base Users (Empty Academic Catalog)**
     ```bash
     php artisan db:seed
     ```
   - **Option B: Realistic Demo Coursework & Data (Recommended)**
     ```bash
     php artisan db:seed --class=DemoDataSeeder
     ```
     *Populates realistic courses (Distributed Systems, Database Architecture, etc.), 7 assignments across all urgency states, study notes, and active subscriptions.*

8. **Start the Laravel backend development server:**
   ```bash
   php artisan serve
   ```
   The backend will be available at: **http://127.0.0.1:8000**

---

### 2. Frontend Web Client

1. **Install Node dependencies:**
   ```bash
   npm install
   ```

2. **Start the Vite development server:**
   ```bash
   npm run dev
   ```
   Open your browser and navigate to **http://127.0.0.1:8000**.

3. **(Optional) Build production assets:**
   ```bash
   npm run build
   ```

---

### 3. Flutter Mobile Client

1. **Navigate to the mobile directory:**
   ```bash
   cd mobile
   ```

2. **Install Flutter packages:**
   ```bash
   flutter pub get
   ```

3. **Configure Environment API Base URL:**
   The mobile client defaults to `http://10.0.2.2:8000/api/v1` for Android Emulators and `http://127.0.0.1:8000/api/v1` for iOS Simulators / Web. You can customize this in `mobile/lib/config/api_config.dart`.

4. **Run the mobile app:**
   ```bash
   flutter run
   ```

---

### 4. Default Demo Accounts

When seeded using `db:seed` or `DemoDataSeeder`, use the following credentials to sign in:

| Role | Email | Password | Default Tier |
| :--- | :--- | :--- | :--- |
| **Student** | `student@due.local` | `password` | Free Tier (or Scholar with Demo Data) |
| **Super Admin** | `admin@due.local` | `password` | Genius Tier (Full Admin Access) |

---

## 🔍 Database Management & Inspection

### Terminal Inspection Tools (Built-in)

- **View database tables, row counts, and connection health:**
  ```bash
  php artisan db:show
  ```

- **Inspect specific schema structures:**
  ```bash
  php artisan db:table classes
  php artisan db:table assignments
  php artisan db:table subscriptions
  ```

- **Interactive Eloquent REPL (`tinker`):**
  ```bash
  php artisan tinker
  ```
  ```php
  // Inspect user and their active subscription
  $user = User::where('email', 'student@due.local')->first();
  $user->subscription_tier;

  // View assignments with their calculated urgency
  Assignment::with('course_class')->get()->map(fn($a) => [$a->title, $a->urgency]);
  ```

### Desktop GUI Clients
You can connect your preferred visual database client to the local Docker MySQL container:
- **[Beekeeper Studio](https://www.beekeeperstudio.io/)** (Recommended, open source)
- **[TablePlus](https://tableplus.com/)**
- **[DBeaver](https://dbeaver.io/)**

**Credentials:**
- **Host**: `127.0.0.1` | **Port**: `3306`
- **User**: `root` | **Password**: `password` | **Database**: `due`

---

## 🧪 Testing & Quality Assurance

Due maintains a high standard of automated test coverage across both backend and mobile layers.

### Backend Tests (Pest PHP)
```bash
# Run the entire test suite (218+ tests)
php artisan test

# Run tests with parallel execution
php artisan test --parallel

# Run specific domain test suites
php artisan test --filter=Assignment
php artisan test --filter=Subscription
php artisan test --filter=SuperAdminStealthAndDashboardTest
```

### Mobile Tests (Flutter)
```bash
cd mobile

# Run Flutter static analysis
flutter analyze

# Run all Flutter widget & unit tests
flutter test
```

### Code Style & Type Safety
```bash
# Format PHP code with Laravel Pint
vendor/bin/pint

# Verify PHP code formatting without changes
vendor/bin/pint --test

# Run TypeScript typecheck
npm run types:check
```

---

## 🔧 Environment Configuration

Key environment variables in `.env`:

| Variable | Description | Default |
| :--- | :--- | :--- |
| `APP_NAME` | Name of the application | `Due` |
| `APP_ENV` | Application environment | `local` |
| `APP_URL` | Base web application URL | `http://127.0.0.1:8000` |
| `DB_CONNECTION` | Database driver | `mysql` |
| `DB_HOST` | Database host | `127.0.0.1` |
| `DB_PORT` | Database port | `3306` |
| `DB_DATABASE` | Database name | `due` |
| `DB_USERNAME` | Database username | `root` |
| `DB_PASSWORD` | Database password | `password` |
| `GEMINI_API_KEY` | Google Gemini API key for Copilot | `(Optional for local mock AI)` |
| `FILESYSTEM_DISK` | Storage driver for uploaded resources | `local` |