# Due — Mobile Application Implementation Plan

A comprehensive engineering specification and roadmap for the **Due Mobile Application**, built with **Flutter** and powered by the **Laravel 13** backend via **Laravel Sanctum** token-based REST API.

---

## 🏛️ Executive Summary & Scope

The **Due Mobile Application** brings the core coursework and deadline management capabilities of Due to mobile devices (iOS & Android). It connects seamlessly to the existing Laravel 13 backend, reusing our established MySQL 8 database schema, Eloquent models, validation rules, and urgency classification logic (`DeadlineUrgencyService`).

---

## 0. Non-Negotiable Directives

1. **Git Commit Rule:**
   - **NEVER run `git commit` or create git commits automatically.** All git commits must be explicitly left to the user.
2. **Strict Zero Corner Radius:**
   - Maintain Due's sharp, technical, and architectural visual identity.
   - Every Flutter widget (buttons, cards, text fields, dialogs, bottom sheets, badges, chips) must use **`BorderRadius.zero`** (`BorderRadius.all(Radius.zero)`).
3. **Dark Theme Default & Cohesive Palette:**
   - Primary dark theme by default: Background `#09090B`, Surface `#18181B`, High-contrast Border `#27272A`, Muted Text `#A1A1AA`, Coral Accent `#FF2D20`.
   - Typography: Clean sans-serif headers and body, monospace font (`Courier` / `JetBrains Mono`) for dates, urgency indicators, and metric numbers.
4. **Theme Persistence in Database:**
   - User appearance preference (`dark`, `light`, `system`) is synchronized directly with the `users.appearance` column via the REST API.
   - Zero `localStorage` or arbitrary unauthenticated caching for user settings.
5. **Business Logic Reusability:**
   - Urgency calculations (`OVERDUE`, `DUE TODAY`, `DUE SOON`, `UPCOMING`) must directly reuse `DeadlineUrgencyService` on the backend so the web and mobile apps always present identical deadline statuses.

---

## 1. System Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          Due Mobile (Flutter)                           │
│                                                                         │
│  ┌───────────────────────────────┐   ┌───────────────────────────────┐  │
│  │ Presentation Layer (Widgets)  │   │ State Layer (ChangeNotifier)  │  │
│  │ - Zero-Radius Cards & Buttons │   │ - AuthProvider                │  │
│  │ - Dark Theme & Monospace Badges│  │ - DashboardProvider           │  │
│  │ - Responsive Screens          │   │ - CourseClassProvider         │  │
│  │                               │   │ - AssignmentProvider          │  │
│  └───────────────┬───────────────┘   └───────────────┬───────────────┘  │
│                  └───────────────┬───────────────────┘                  │
│                                  ▼                                      │
│                  ┌───────────────────────────────┐                      │
│                  │ Network Layer (ApiClient)     │                      │
│                  │ - Bearer Token Injection      │                      │
│                  │ - 401 Session Interceptor     │                      │
│                  │ - JSON Serialization          │                      │
│                  └───────────────┬───────────────┘                      │
│                                  │                                      │
│                  ┌───────────────▼───────────────┐                      │
│                  │ flutter_secure_storage        │                      │
│                  │ (Encrypted Token Storage)     │                      │
│                  └───────────────┬───────────────┘                      │
└──────────────────────────────────┼──────────────────────────────────────┘
                                   │ HTTPS JSON REST API
                                   │ Authorization: Bearer <sanctum_token>
                                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           Laravel 13 Backend                            │
│                                                                         │
│  ┌────────────────────────┐         ┌────────────────────────────────┐  │
│  │ routes/api.php         │────────►│ auth:sanctum Middleware        │  │
│  └────────────────────────┘         └───────────────┬────────────────┘  │
│                                                     ▼                   │
│                                     ┌────────────────────────────────┐  │
│                                     │ Api/V1 Resource Controllers    │  │
│                                     │ - AuthController               │  │
│                                     │ - DashboardApiController       │  │
│                                     │ - CourseClassApiController     │  │
│                                     │ - AssignmentApiController      │  │
│                                     │ - AssignmentNoteApiController  │  │
│                                     └───────────────┬────────────────┘  │
│                                                     ▼                   │
│                                     ┌────────────────────────────────┐  │
│                                     │ DeadlineUrgencyService         │  │
│                                     │ (Canonical Urgency Engine)     │  │
│                                     └───────────────┬────────────────┘  │
│                                                     ▼                   │
│                                     ┌────────────────────────────────┐  │
│                                     │ MySQL 8 Database (Shared)      │  │
│                                     └────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. API Contract & Endpoints (`/api/v1/`)

All requests accept `Accept: application/json` and `Content-Type: application/json`.
Authenticated routes require `Authorization: Bearer <personal_access_token>`.

### 2.1 Authentication & Profile
- **`POST /api/v1/auth/register`**
  - **Payload:** `{ "name": "John Doe", "email": "john@example.com", "password": "password", "password_confirmation": "password" }`
  - **Response (201):** `{ "message": "Registered successfully", "token": "1|xyz...", "user": { "id": 1, "name": "John Doe", "email": "john@example.com", "appearance": "dark" } }`
- **`POST /api/v1/auth/login`**
  - **Payload:** `{ "email": "john@example.com", "password": "password", "device_name": "Flutter Mobile" }`
  - **Response (200):** `{ "message": "Authenticated", "token": "2|abc...", "user": { ... } }`
- **`POST /api/v1/auth/logout`**
  - **Response (200):** `{ "message": "Logged out successfully" }`
- **`GET /api/v1/auth/user`**
  - **Response (200):** `{ "user": { "id": 1, "name": "John Doe", "email": "john@example.com", "appearance": "dark", "created_at": "..." } }`
- **`PATCH /api/v1/auth/appearance`**
  - **Payload:** `{ "appearance": "dark" }` (`dark` | `light` | `system`)
  - **Response (200):** `{ "message": "Appearance updated", "appearance": "dark" }`

### 2.2 Dashboard Overview
- **`GET /api/v1/dashboard`**
  - **Response (200):**
    ```json
    {
      "metrics": {
        "total": 12,
        "pending": 5,
        "in_progress": 3,
        "completed": 4,
        "overdue": 1
      },
      "upcoming_assignments": [
        {
          "id": 10,
          "title": "Database Normalization",
          "due_date": "2026-10-15T23:59:00Z",
          "status": "pending",
          "urgency": "DUE SOON",
          "urgency_color": "yellow",
          "course_class": {
            "id": 2,
            "name": "Database Systems"
          }
        }
      ]
    }
    ```

### 2.3 Course Classes (CRUD)
- **`GET /api/v1/classes`**
  - Lists all user courses with `assignments_count`.
- **`POST /api/v1/classes`**
  - **Payload:** `{ "name": "Software Engineering", "instructor_name": "Dr. Smith", "instructor_contact": "smith@uni.edu", "credit_hours": 3, "ects": 5 }`
- **`GET /api/v1/classes/{id}`**
  - Returns class details along with its associated assignments.
- **`PUT /api/v1/classes/{id}`**
  - Updates class information.
- **`DELETE /api/v1/classes/{id}`**
  - Deletes class (fails with 422 if assignments are attached).

### 2.4 Assignments (CRUD & Filtering)
- **`GET /api/v1/assignments`**
  - **Query Params:** `?status=pending&class_id=2&urgency=overdue&search=quiz`
  - Returns paginated or ordered assignment list with calculated urgency and class details.
- **`POST /api/v1/assignments`**
  - **Payload:** `{ "class_id": 2, "title": "Homework 1", "description": "...", "due_date": "2026-10-20 18:00:00", "status": "pending" }`
- **`GET /api/v1/assignments/{id}`**
  - Returns full assignment details with urgency and notes list.
- **`PUT /api/v1/assignments/{id}`**
  - Updates title, description, due date, course class, or status.
- **`PATCH /api/v1/assignments/{id}/status`**
  - Quick status toggle: `{ "status": "completed" }` (`pending`, `in_progress`, `completed`).
- **`DELETE /api/v1/assignments/{id}`**
  - Permanently removes the assignment and cascaded notes.

### 2.5 Assignment Notes (CRUD)
- **`GET /api/v1/assignments/{assignmentId}/notes`**
- **`POST /api/v1/assignments/{assignmentId}/notes`**
  - **Payload:** `{ "content": "Refer to lecture 4 slides for question 2" }`
- **`PUT /api/v1/assignments/{assignmentId}/notes/{id}`**
- **`DELETE /api/v1/assignments/{assignmentId}/notes/{id}`**

---

## 3. Flutter Application Architecture

Located in `mobile/` in the project root.

```
mobile/
├── pubspec.yaml
├── lib/
│   ├── main.dart                       # App entrypoint, Provider registration, Theme setup
│   ├── config/
│   │   └── api_config.dart             # Base URLs (Android emulator 10.0.2.2 vs physical device / local)
│   ├── theme/
│   │   ├── app_colors.dart             # Zinc dark palette (#09090B, #18181B, #27272A, #FF2D20)
│   │   └── app_theme.dart              # ThemeData with zero corner radius across all components
│   ├── models/
│   │   ├── user.dart                   # User model with appearance preference
│   │   ├── course_class.dart           # Class model with credit hours & assignment counts
│   │   ├── assignment.dart             # Assignment model with status & computed urgency
│   │   ├── assignment_note.dart        # Assignment note model
│   │   └── dashboard_metrics.dart      # Numerical stats model
│   ├── services/
│   │   ├── token_storage.dart          # flutter_secure_storage wrapper
│   │   └── api_client.dart             # HTTP client with Bearer header & 401 handler
│   ├── providers/
│   │   ├── auth_provider.dart          # Authentication state & login/register/logout actions
│   │   ├── dashboard_provider.dart     # Overview stats & upcoming deadlines
│   │   ├── course_provider.dart        # Courses CRUD state
│   │   └── assignment_provider.dart    # Assignments CRUD, filtering, & search state
│   ├── screens/
│   │   ├── splash_screen.dart          # Token verification on app boot
│   │   ├── auth/
│   │   │   ├── login_screen.dart       # Sharp login form
│   │   │   └── register_screen.dart    # Sharp account creation form
│   │   ├── main_navigation_screen.dart # Bottom navigation bar (Dashboard, Courses, Assignments, Profile)
│   │   ├── dashboard/
│   │   │   └── dashboard_screen.dart   # Metric cards, overdue banner, upcoming deadlines feed
│   │   ├── courses/
│   │   │   ├── courses_list_screen.dart# Courses directory with CH/ECTS badges
│   │   │   ├── course_detail_screen.dart# Course overview & linked assignments
│   │   │   └── course_form_dialog.dart # Create & edit course modal
│   │   ├── assignments/
│   │   │   ├── assignments_list_screen.dart # Filter tabs, search bar, list
│   │   │   ├── assignment_detail_screen.dart# Urgency countdown, details, notes list
│   │   │   └── assignment_form_screen.dart  # Create & edit assignment form
│   │   └── settings/
│   │       └── settings_screen.dart    # Theme selector (DB persisted), user profile, logout
│   └── widgets/
│       ├── zero_button.dart            # Sharp architectural button
│       ├── zero_card.dart              # Sharp container with 1px border
│       ├── zero_text_field.dart        # Sharp border input field
│       ├── urgency_badge.dart          # Monospace colored status badge
│       ├── metric_card.dart            # 2-column dashboard numerical card
│       └── empty_state.dart            # Clean architectural empty state indicator
```

---

## 4. Phase-by-Phase Implementation Roadmap

### **Phase M1: Backend REST API & Laravel Sanctum Setup**
*Goal: Expose fully tested, token-authenticated REST endpoints reusing models, policies, and urgency service.*

- [x] Run `php artisan install:api` to scaffold `laravel/sanctum` and publish `routes/api.php`.
- [x] Add `Laravel\Sanctum\HasApiTokens` to `App\Models\User`.
- [x] Create `App\Http\Controllers\Api\V1\AuthController` (`login`, `register`, `logout`, `user`, `appearance`).
- [x] Create `App\Http\Controllers\Api\V1\DashboardApiController` (`index` returning metrics and upcoming list via `DeadlineUrgencyService`).
- [x] Create `App\Http\Controllers\Api\V1\CourseClassApiController` (`index`, `store`, `show`, `update`, `destroy` with assignment protection).
- [x] Create `App\Http\Controllers\Api\V1\AssignmentApiController` (`index` with filters, `store`, `show`, `update`, `destroy`, `updateStatus`).
- [x] Create `App\Http\Controllers\Api\V1\AssignmentNoteApiController` (`index`, `store`, `update`, `destroy`).
- [x] Register all endpoints in `routes/api.php` under prefix `v1` and group `auth:sanctum`.
- [x] Write comprehensive feature tests covering auth, dashboard, classes, assignments, and notes.
- [x] Verify test suite passes (`php artisan test`: 151 tests, 142 passed, 0 failures) and clean code with `vendor/bin/pint`.

---

### **Phase M2: Flutter Scaffold & Architectural Core**
*Goal: Initialize Flutter project with Zero-Radius Design System and API networking.*

- [x] Scaffold Flutter app in `mobile/` using `flutter create --org com.due due_mobile`.
- [x] Configure `pubspec.yaml` with required packages (`http`, `flutter_secure_storage`, `provider`, `intl`).
- [x] Build `AppColors` and `AppTheme`:
  - Dark mode by default (`#09090B`).
  - Strict zero radius on all widgets: `ElevatedButtonThemeData`, `OutlinedButtonThemeData`, `CardTheme`, `InputDecorationTheme`, `DialogTheme`, `BottomSheetThemeData`, `ChipThemeData`.
  - Monospace font styling for badges.
- [x] Implement `TokenStorage` with `flutter_secure_storage`.
- [x] Implement `ApiClient` with automatic Bearer token injection and global 401 unauthenticated redirect.
- [x] Build core architectural widgets (`ZeroButton`, `ZeroCard`, `ZeroTextField`, `UrgencyBadge`, `MetricCard`, `EmptyState`, `ConfirmDialog`).
- [x] Verified with `flutter analyze` (0 issues) and `flutter test` (all tests passed).

---

### **Phase M3: Mobile Authentication & Session Flow**
*Goal: Complete login, registration, and persistent sessions.*

- [x] Implement `AuthProvider` managing login status, user profile, and token lifecycle.
- [x] Create `SplashScreen` checking stored token and verifying session with `GET /api/v1/auth/user`.
- [x] Create `LoginScreen` with email and password inputs, validation errors, and loading state.
- [x] Create `RegisterScreen` with name, email, password, and password confirmation.
- [x] Add logout action that revokes the Sanctum token on the server and purges `TokenStorage`.
- [x] Verified with `flutter analyze` (0 issues) and `flutter test` (all 4 tests passed).

---

### **Phase M4: Dashboard & Urgency Metrics**
*Goal: Instant mobile overview of coursework and impending deadlines.*

- [ ] Implement `DashboardProvider` fetching `GET /api/v1/dashboard`.
- [ ] Build 2-column numerical `MetricCard` grid (Total, Pending, In Progress, Completed, Overdue).
- [ ] Build overdue alert banner displaying when overdue assignments need attention.
- [ ] Build upcoming deadlines feed showing course, formatted due date, urgency badge, and quick one-tap status completion.
- [ ] Add pull-to-refresh functionality on the dashboard.

---

### **Phase M5: Courses & Classes Management**
*Goal: Academic subject tracking on mobile.*

- [ ] Implement `CourseProvider` handling course listing and mutations.
- [ ] Build `CoursesListScreen` showing credit hours (CH) and ECTS badges.
- [ ] Build `CourseDetailScreen` showing course syllabus info and attached assignments.
- [ ] Build `CourseFormDialog` for creating and editing classes.
- [ ] Implement deletion safeguard with clear warning when assignments exist for the course.

---

### **Phase M6: Assignments, Filtering & Search**
*Goal: Complete assignment workflow on the go.*

- [ ] Implement `AssignmentProvider` with search querying, class filter, and status filter (`All`, `Pending`, `In Progress`, `Completed`).
- [ ] Build `AssignmentsListScreen` with status tab selector, instant search bar, and assignment cards.
- [ ] Build `AssignmentDetailScreen` displaying deadline countdown, full description, urgency badge, and course badge.
- [ ] Implement inline status picker allowing immediate transition between Pending, In Progress, and Completed.
- [ ] Build `AssignmentFormScreen` for creating and editing assignments with class selector and date picker.

---

### **Phase M7: Assignment Notes CRUD**
*Goal: Quick study notes and reminders attached to coursework.*

- [ ] Embed notes list inside `AssignmentDetailScreen`.
- [ ] Build modal dialog to add new notes and edit existing notes.
- [ ] Build delete note action with confirmation dialog.
- [ ] Verify instant reactive update of notes in state.

---

### **Phase M8: Testing, Polishing & Verification**
*Goal: Quality assurance and end-to-end integration.*

- [ ] Run `flutter analyze` on the mobile codebase ensuring 0 errors or warnings.
- [ ] Verify dark and light themes adhere strictly to zero-radius design rules.
- [ ] Run full backend test suite (`php artisan test`) ensuring 100% pass rate.
- [ ] Validate end-to-end user flow: Register -> Create Class -> Create Assignment -> Change Status -> Add Note -> Check Dashboard Metrics.

---

## 5. Verification Checklist & Success Criteria

| Milestone | Acceptance Criteria |
| :--- | :--- |
| **Sanctum Auth** | Login issues token; protected routes return 401 without token; logout revokes token. |
| **Parity with Web** | `DeadlineUrgencyService` calculates urgency identically on Web and Mobile. |
| **Zero Radius** | Every mobile button, input, card, badge, dialog has 0 corner radius. |
| **Theme Sync** | Changing theme updates `users.appearance` in DB via API; zero local storage. |
| **Course Protection**| Deleting a class with assignments fails with an informative error message. |
| **Performance** | Instant pull-to-refresh updates; smooth animations; proper error feedback. |
