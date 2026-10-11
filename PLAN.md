# Project: Assignment Tracker — Laravel + React + Inertia.js

Act as a senior full-stack developer and mentor. Build a clean, functional, maintainable Assignment Tracker web application that I can use as a learning project during my software engineering internship.

This project is intended to teach me Laravel, PHP, Eloquent ORM, React, Inertia.js, MySQL, authentication, CRUD operations, database relationships, and how to identify and prevent the N+1 query problem.

**Prioritize correctness, simplicity, maintainability, and learning over unnecessary features or architectural complexity.** Use established Laravel conventions and current, non-deprecated APIs.

## 0. Non-Negotiable Directives & Learning Workflow

1. **Git Commit Rule:**
   - **Never commit yourself.** The AI coding assistant must **never** run `git commit` or create commits. The user will handle all git commits.
2. **Phase-by-Phase Learning Workflow:**
   - Strictly follow the phases outlined in this plan, progressing one phase at a time.
   - This project is for learning purposes: build one phase, verify it, clearly explain the concepts and architecture so the user understands everything, and pause for review before proceeding to the next phase.
3. **UI Aesthetic — Laravel.com Inspired:**
   - **Visual Identity:** Inspired by the official Laravel website (https://laravel.com/) — structured, technical, sharp, and architectural.
   - **Zero Corner Radius Rule:** Every button, input, card, modal, badge, dropdown, table, and container MUST have **0 corner radius** (`rounded-none` / `border-radius: 0`). It should feel edgy, sharp, architectural, and simple.
   - **Primary Dark Theme (Default):** The application is dark themed by default (deep dark backgrounds, subtle geometric borders, crisp contrast, and refined Laravel red/coral accents).
4. **Theme System & Tailwind Styling:**
   - **No Hard-Coded Style Values:** Never use arbitrary, hard-coded values (no ad-hoc hex values, random paddings, or inline styling).
   - **Structured Theme System:** Implement a proper theme system using CSS variables mapped into Tailwind tokens so the entire interface is consistent and customizable.
   - **Tailwind-First:** Use Tailwind CSS for all styling. Do not write plain CSS files all over the place unless strictly necessary for base theme tokens or global resets.


## 1. Mandatory technology stack

Use the following technologies:

- **Backend:** Laravel and PHP, using the versions compatible with the existing project and its dependencies.
- **Frontend:** React with TypeScript and Inertia.js.
- **Database:** MySQL.
- **ORM:** Laravel Eloquent ORM for all ordinary database operations. Do not introduce another ORM or write raw SQL for operations that Eloquent can handle naturally.
- **Authentication:** Laravel's recommended authentication setup for an Inertia.js React application, using session-based authentication for the website.
- **Styling:** Tailwind CSS, following the version and conventions already established by the project.
- **Validation:** Laravel Form Requests where appropriate, with useful validation errors displayed in the React interface.
- **Testing:** Laravel's supported testing tools, including feature tests and database tests.

Use Laravel's official conventions for routing, controllers, migrations, models, relationships, middleware, validation, authorization, and error handling.

Do not introduce additional frameworks, libraries, design systems, or packages unless they solve a real requirement.

## 2. Development approach and scope

Build the **website first**. Do not implement the Flutter application yet.

Before making changes:

1. Inspect the existing repository, its directory structure, installed dependencies, framework versions, environment configuration, and current implementation.
2. Determine whether this is an existing Laravel application or a new project.
3. If a project already exists, preserve working code and follow its established conventions where appropriate.
4. If the project is empty, establish a minimal Laravel + React + Inertia.js setup using the official, currently supported approach.
5. Check the relevant official documentation for version-specific commands and APIs instead of relying on outdated examples.

Work incrementally. Implement a functional vertical slice before expanding into the remaining features.

Do not replace working application code unnecessarily. Do not perform destructive database operations, overwrite environment files, or expose credentials.

Keep the application small enough for a student to understand and explain during an internship review.

## 3. Core application features

### A. Authentication

Implement:

- User registration.
- Login and logout.
- Password hashing using Laravel's standard mechanisms.
- Appropriate validation and useful error messages.
- Protected routes for authenticated users.
- Password reset if it is supported by the selected starter kit without excessive additional setup.

Every user's academic information must remain private.

A user must never be able to read, update, delete, or access another user's classes, assignments, or notes by manipulating a URL, form field, or request.

Enforce ownership on the server, not merely by hiding buttons in React.

Use Laravel policies or another conventional authorization mechanism where appropriate. Scope database queries to the authenticated user and validate ownership when associating records.

### B. Classes

Users should be able to create, view, edit, delete, and list their academic classes or courses.

Each class should have the following fields:

- Course name — required.
- Teacher name — optional.
- Teacher contact information — optional.
- Credit hours — optional numeric value.
- ECTS — optional numeric value.

Use a suitable database representation for credit hours and ECTS. Allow either to be absent because some courses may not provide both values.

Provide:

- A classes listing page.
- A class details page.
- A form for creating and editing classes.
- A way to see the assignments associated with a class.
- Confirmation before deleting a class that has assignments.

Deleting a class must not silently destroy assignments or their notes. Prefer restricting deletion while assignments exist and explaining to the user why the class cannot be deleted. Choose a consistent database foreign-key strategy that enforces this rule.

Prevent duplicate or invalid associations where appropriate, but do not invent complicated academic administration features.

### C. Assignments

This is the central feature of the application.

Users should be able to create, view, edit, delete, filter, and manage their assignments.

Each assignment should include:

- **Title:** A short, required name for the assignment.
- **Description:** What needs to be done, including optional instructions or requirements.
- **Class:** The class to which the assignment belongs.
- **Status:** Pending, In Progress, or Completed.
- **Deadline:** The date and time by which the assignment must be completed.
- **Notes:** Zero or more separate notes associated with the assignment.

Use sensible database types, validation rules, indexes, and foreign keys.

The class association must be required, and the selected class must belong to the authenticated user.

Provide an assignment details page showing the description, class information, deadline, remaining time, status, remarks, and notes.

Provide convenient status updates from the assignment list and details page without bypassing server-side validation or authorization.

Do not add file uploads, assignment submissions, grading systems, teacher accounts, collaboration, or notifications in the first version.

### D. Deadline calculations and remarks

Implement deadline calculations on the server using Laravel and PHP's supported date and time functionality. Do not store a continuously changing remaining-time value in the database.

For each assignment, display:

- A human-readable remaining-time indicator.
- The exact deadline.
- Whether the assignment is upcoming, due today, or overdue.
- A remark indicating the urgency of the deadline.

Use clear rules such as:

- **Completed:** Show that the assignment is completed, regardless of its past deadline.
- **Overdue:** The deadline has passed and the assignment is not completed. Display a strong warning.
- **Due today:** The deadline is today but has not passed. Indicate that immediate attention is needed.
- **Due soon:** The deadline is approaching within a reasonable configurable or clearly defined period.
- **Upcoming:** The deadline is sufficiently far away.

Calculate urgency from the actual deadline and current time, not only the calendar date.

Handle time zones consistently and display dates in a clear, user-friendly format. Use the application's configured timezone and avoid confusing differences between the server and browser.

For example, if an assignment is due at 4:00 PM, it must become overdue after 4:00 PM, not automatically at midnight.

Ensure that completed assignments do not continue to appear overdue simply because their original deadlines have passed.

Keep the urgency rules in a reusable service or another appropriate application layer so they can later be reused by the mobile API. Do not duplicate the same business rules across several controllers.

### E. Multiple notes per assignment

Users should be able to add, edit, view, and delete multiple notes for a single assignment.

Each note should contain:

- Note content — required.
- Creation and update timestamps.

Use a separate `AssignmentNote` model and database table, related to the assignment through Eloquent.

Notes must be accessible only through assignments that belong to the authenticated user.

Display notes in a readable list on the assignment details page, including their creation dates.

Keep notes simple. Do not add rich-text editors, file attachments, note sharing, or complicated version history.

### F. Dashboard

Create a useful dashboard that gives the user an overview of their academic workload.

Include numerical summary cards for:

- Total assignments.
- Pending assignments.
- In-progress assignments.
- Completed assignments.
- Overdue assignments.

Include an upcoming assignments section, ordered by deadline, with the nearest relevant deadlines displayed first.

Each assignment entry should show its title, class name, status, deadline, remaining time, and urgency remark.

Include a simple performance analysis section based on actual assignment data, such as:

- Completion rate.
- On-time completion rate, when enough historical data is available.
- Completed versus incomplete assignments.
- Assignment workload by class.
- A simple weekly or monthly completion trend if it can be implemented without unnecessary complexity.

Define the calculations clearly. Do not present invented data or misleading percentages. Handle empty states and division by zero.

If on-time completion is part of the analysis, store a suitable completion timestamp and use it to determine whether the assignment was completed before its deadline. Explain the distinction between completed assignments and assignments completed on time.

Use Eloquent aggregates, relationship counts, and appropriately grouped database queries instead of loading every assignment into PHP just to calculate dashboard statistics.

Do not build a sophisticated analytics engine. A few accurate summary cards and one or two simple visualizations are enough.

### G. Assignment filtering and search

The assignments page must support filtering by:

- Status.
- Class.
- Deadline start date.
- Deadline end date.
- Overdue assignments.
- Upcoming assignments.

Include text search by assignment title where practical.

Allow filters to be combined. Validate date ranges, and handle cases where the start date is later than the end date.

Keep filters in the URL through query parameters so users can refresh the page, bookmark a filtered view, or navigate between pages without losing their filter state.

Use server-side filtering and pagination. Do not fetch all assignments and filter them exclusively in React.

Provide a clear way to reset filters.

Use consistent ordering, with sensible defaults such as the nearest deadline first. Handle assignments without deadlines only if the data model permits them; otherwise, require a deadline.

### H. User profile

Create a profile page where users can view and update their own information.

Include:

- Name.
- Email address.
- Password change.
- Account information.

Validate changes on the server. If the email address changes, apply the appropriate uniqueness validation and any verification behavior supported by the chosen authentication setup.

Do not expose sensitive information such as password hashes or authentication tokens in page props or logs.

### I. Settings

Create a settings area with a small number of useful options.

**Appearance**

- Light theme.
- Dark theme.
- System theme.

Persist the user's selected theme so it remains consistent after refreshing or signing in again. Prefer a small, conventional implementation over a complex theme management system.

**Devices and sessions**

Provide a page where users can see the devices or sessions associated with their account, to the extent supported by the selected Laravel authentication and session configuration.

If session metadata is needed, implement the smallest reasonable solution and explain any configuration requirements.

Allow the user to log out other supported sessions when practical, while preserving the current session. Handle session invalidation securely.

Do not claim to provide complete device tracking if the underlying system only stores sessions or access tokens.

Do not store or display raw authentication tokens unnecessarily.

## 4. Database design and Eloquent ORM

Use Eloquent ORM as the primary way to read and modify application data.

Start with a simple relational design containing these core tables:

### Users

Use the authentication system's standard users table, extending it only when needed.

### Classes

Suggested fields:

- `id`
- `user_id`
- `course_name`
- `teacher_name`, nullable
- `teacher_contact`, nullable
- `credit_hours`, nullable
- `ects`, nullable
- `created_at`
- `updated_at`

### Assignments

Suggested fields:

- `id`
- `user_id`
- `class_id`
- `title`
- `description`, nullable
- `status`
- `deadline`
- `completed_at`, nullable
- `created_at`
- `updated_at`

### Assignment notes

Suggested fields:

- `id`
- `assignment_id`
- `content`
- `created_at`
- `updated_at`

Use Laravel migrations to create and modify the schema. Define appropriate foreign keys and indexes.

The `user_id` on assignments can help scope queries directly to the current user. Ensure that the assignment's class belongs to the same user; a valid class ID alone is not sufficient.

Define appropriate Eloquent relationships, including:

- User has many classes.
- User has many assignments.
- Class belongs to a user.
- Class has many assignments.
- Assignment belongs to a user.
- Assignment belongs to a class.
- Assignment has many notes.
- Assignment note belongs to an assignment.

Use conventional model names, foreign keys, relationship methods, casts, and mass-assignment protection.

Use database transactions when an operation genuinely requires multiple related database changes to succeed or fail together.

Do not create unnecessary repositories, generic CRUD frameworks, custom ORM abstractions, or excessive service classes. Introduce an application service when it encapsulates reusable business logic or materially improves clarity.

Keep the implementation understandable to a developer who is learning Laravel.

## 5. Explicit N+1 prevention and learning requirements

One of the main goals of this project is to understand and prevent the N+1 query problem.

Do not merely write code that appears optimized. Implement and verify query behavior.

For example, the assignments list may display the associated class name for every assignment. Loading each assignment's class independently can cause an additional database query per row.

Use Eloquent eager loading where appropriate, for example:

`Assignment::with('class')`

Use relationship counts when displaying counts, for example:

`ClassModel::withCount('assignments')`

Use aggregates and database-side filtering for dashboard statistics instead of retrieving entire collections unnecessarily.

Inspect the queries generated by important pages, particularly:

- Dashboard.
- Assignments list.
- Classes list.
- Assignment details.
- Performance analysis.

Use Laravel's query logging or a suitable development-only query inspection tool to verify the behavior.

Check for N+1 problems in nested relationships too, such as assignments, their classes, and their notes.

Where supported by the installed Laravel version, consider enabling Eloquent's automatic prevention of lazy loading during development or in tests so accidental lazy loading is easier to detect. Do not use deprecated APIs.

Do not enable a production setting that unexpectedly breaks legitimate requests. Choose an appropriate development and test configuration.

Add automated tests or query-count assertions for at least one important listing scenario. Avoid brittle tests that depend on an exact number of framework-internal queries unless the environment is controlled.

Document one example of the original N+1 problem, the change made to solve it, and how the improved behavior was verified.

The goal is to understand why the optimization works, not just to memorize `with()`.

## 6. Web architecture and future Flutter compatibility

Although the first deliverable is the website, design the backend so that a Flutter application can be added later without rewriting the core business logic.

Use a clear separation between:

- HTTP routing.
- Request validation.
- Authorization.
- Application or domain logic where appropriate.
- Eloquent persistence.
- Inertia page responses.

Keep deadline calculations, ownership rules, and other reusable business logic out of React components.

Avoid putting every operation into a large controller. Equally, do not split every simple CRUD action into unnecessary classes.

When appropriate, make application logic independent of whether the request originated from an Inertia page or a future JSON API.

**Do not implement the Flutter application in this phase.** Do not build mobile screens or spend time on mobile-specific UI.

Also, do not build a complete public API merely for hypothetical future requirements. Instead, prepare a clear API extension plan and avoid architectural choices that would make the API difficult to add.

For the future mobile client, plan to use:

- Laravel Sanctum for token-based API authentication.
- Separate JSON API routes and appropriately structured JSON responses.
- Request validation and authorization equivalent to the web application.
- The same MySQL database, Eloquent models, and business rules.
- Secure token storage and token revocation on the Flutter side.

Do not reuse browser session authentication as if it were automatically suitable for a standalone Flutter client.

If Sanctum is already installed or required for the web setup, configure it using supported conventions. Do not introduce unnecessary authentication packages.

## 7. React and Inertia.js implementation

Use React with TypeScript and Inertia.js for the website.

Use Inertia for web navigation, page rendering, form submissions, validation errors, and redirects. Use Laravel controllers to render the appropriate Inertia pages and provide the data required by each page.

Do not turn the application into a separate React single-page application that fetches every page from a custom API.

Use reusable components for common interface elements, such as:

- Application layout.
- Sidebar and mobile navigation.
- Page headers.
- Summary cards.
- Status indicators.
- Assignment tables or cards.
- Filter controls.
- Form fields.
- Confirmation dialogs.
- Empty states.
- Pagination.

Use shared components where they improve consistency, but do not create an oversized component library for this small project.

Keep TypeScript types accurate. Avoid widespread `any` types, unnecessary type assertions, and duplicated definitions when types can be shared or inferred safely.

Use appropriate loading, validation, success, and error states. Avoid unnecessary client-side state when Inertia already provides the required page data and navigation behavior.

## 8. UI and responsive design

Create a polished, modern, architectural academic productivity interface inspired directly by **laravel.com**.

- **Laravel.com Visual Aesthetic:** Crisp, high-contrast, technical, and minimal. Use structured grid borders, clean lines, and signature Laravel accent touches (e.g. vibrant red/coral `#ff2d20` / `#f43f5e`).
- **Zero Corner Radius Rule:** Every button, input field, card container, modal, badge, dropdown, table, and dialog MUST have **0 corner radius** (`rounded-none` or `border-radius: 0`). The UI must feel sharp, edgy, structured, and simple.
- **Default Dark Theme:** The interface is dark themed by default. Deep dark zinc/black backgrounds (e.g., `#09090b`, `#121215`), subtle high-contrast borders (`#27272a`), muted secondary text, and bright readable foreground typography.
- **Strict Theme Variable System:**
  - Never use hard-coded style values or ad-hoc magic hex codes in component templates.
  - All colors, borders, and surfaces must route through semantic CSS theme variables mapped to Tailwind utilities (e.g., `bg-background`, `text-foreground`, `border-border`, `bg-card`, `text-muted`, `bg-accent`, `bg-primary`, etc.).
  - Tailwind CSS is the standard styling tool; avoid scattered, arbitrary plain CSS files.
- **Typography & Details:** Clean geometric sans-serif (e.g., Inter/Geist/Outfit) paired with monospace accents for dates, status tags, and numerical counts.

The design should feel suitable for a university student, not like an enterprise administration system overloaded with charts and controls.

The application must be fully responsive on:

- Desktop computers.
- Laptops.
- Tablets.
- Mobile phone browsers.

On desktop, use a sidebar or another clear navigation structure.

On smaller screens, use an appropriate compact navigation pattern. Tables should adapt into readable cards or use carefully designed horizontal scrolling where necessary. Forms must remain usable without horizontal overflow.

Make dashboard cards and charts responsive.

Provide clear visual distinctions between pending, in-progress, completed, due-today, and overdue assignments. Do not rely on color alone to communicate status.

Support keyboard navigation, visible focus states, accessible form labels, and appropriate color contrast.

Include useful empty states, such as when a user has not created any classes or assignments.

Use realistic sample data only through seeders intended for development or demonstration. Do not show fabricated statistics in a real user's dashboard.

Avoid unnecessary animations, excessive gradients, decorative clutter, and heavy component libraries.

## 9. Validation, security, and reliability

Follow Laravel security conventions.

At minimum:

- Validate all incoming data on the server.
- Protect state-changing web requests using Laravel's normal CSRF protection.
- Enforce authentication and record ownership on every protected operation.
- Use Eloquent mass-assignment protection.
- Validate status values against the allowed set.
- Validate numeric credit and ECTS values.
- Validate deadlines and date-range filters.
- Prevent unauthorized cross-user class and assignment associations.
- Handle missing records with appropriate responses.
- Avoid exposing stack traces or sensitive configuration in production.
- Do not commit `.env` files, credentials, tokens, or secrets.
- Use database constraints to reinforce application-level rules.
- Use Laravel's standard password hashing and session security mechanisms.
- Do not invent custom cryptography or authentication schemes.

Do not rely exclusively on frontend validation.

Use appropriate HTTP methods and conventional status codes or redirects. Display understandable validation and error messages to users.

## 10. Automated testing

Write meaningful tests for the application's critical behavior.

At minimum, test:

**Authentication**
- Guests cannot access protected pages.
- Authenticated users can access their own pages.
- Logout invalidates the appropriate session.

**Classes**
- An authenticated user can create, view, update, and delete a class when allowed.
- Validation rejects invalid input.
- A user cannot access or modify another user's class.
- A class with assignments cannot be deleted if the chosen deletion rule restricts it.

**Assignments**
- An authenticated user can create, view, update, and delete an assignment.
- Invalid data is rejected.
- Assignment ownership is enforced.
- A user cannot associate an assignment with another user's class.
- Filtering and pagination work correctly.
- Status changes and completion timestamps are handled consistently.

**Deadline logic**
- Upcoming assignments receive the appropriate remark.
- Assignments due today are handled correctly.
- An incomplete assignment past its deadline is overdue.
- A completed assignment is not shown as overdue.
- Remaining-time calculations handle boundary conditions correctly.

Use a reliable clock abstraction or frozen time in tests when testing deadlines.

**Notes**
- Multiple notes can belong to one assignment.
- Notes cannot be accessed through another user's assignment.
- Unauthorized note changes are rejected.

**Dashboard**
- Summary statistics are correct.
- Empty states do not cause errors.
- Completion rates and on-time statistics use clearly defined calculations.

**Query behavior**
- Important list pages eager-load the relationships they display.
- Tests or query inspection verify that query counts do not grow linearly with the number of assignments merely because each assignment displays its class.

Use factories and seeders appropriately. Tests must not depend on production data or require destructive operations against a real database.

Run the relevant tests and resolve failures before declaring the implementation complete.

## 11. Project organization and code quality

Follow the existing Laravel project's structure and conventions.

Use Form Requests when they improve clarity, policies for authorization when appropriate, and focused controllers for HTTP concerns.

Keep migrations, models, React pages, reusable components, and tests organized in their conventional locations.

Do not:

- Put all business logic in one controller.
- Put deadline logic directly in React.
- Make database queries from React components.
- Fetch every record just to perform filtering in the browser.
- Introduce microservices or a repository pattern without a genuine need.
- Create unnecessary abstractions around basic Eloquent operations.
- Add features outside the defined scope without asking first.
- use deprecated Laravel, React, or Inertia APIs.
- Suppress warnings instead of understanding them.
- Claim that tests pass without running them.

Prefer readable code over clever code.

## 12. Implementation order

Implement the project in the following phases. Strictly proceed phase by phase: build one phase, verify and test it, explain the concepts and mechanics so the developer learns thoroughly, and obtain review before advancing to the next phase.

**Phase 1 — Inspect and establish the project**

Inspect the repository and versions, confirm the setup, configure the application for MySQL, set up the initial Laravel + React + Inertia.js application with Tailwind CSS and the dark theme tokens, and ensure it runs cleanly.

**Phase 2 — Authentication and database**

Implement authentication, migrations, models, Eloquent relationships, factories, and initial tests.

**Phase 3 — Classes and assignments**

Implement complete CRUD operations for classes and assignments, including server-side validation, ownership enforcement, and pagination.

**Phase 4 — Notes and deadline logic**

Implement multiple notes per assignment, remaining-time calculations, and urgency remarks, with appropriate automated tests.

**Phase 5 — Dashboard and filters**

Implement summary statistics, upcoming assignments, simple performance analysis, combined filters, search, and pagination. Inspect database queries and address N+1 problems.

**Phase 6 — Profile and settings**

Implement profile management, persistent theme selection, and an appropriately scoped session or device management page.

**Phase 7 — UI refinement**

Ensure all pages are consistent, accessible, polished, and responsive on desktop and mobile browsers.

**Phase 8 — Verification and documentation**

Run migrations in the intended development environment, execute tests, verify the main user workflows, inspect query behavior, and document how to run and understand the application.

If a phase depends on an unresolved issue, address that issue before proceeding. Do not leave a collection of incomplete screens and claim the application is finished.

## 13. Final deliverables

When the implementation is complete, provide:

1. A working Laravel + React + Inertia.js website connected to MySQL.
2. Authentication, protected user data, and appropriate authorization.
3. Functional CRUD for classes, assignments, and assignment notes.
4. Accurate deadline calculations and urgency remarks.
5. A dashboard with real summary statistics and useful performance analysis.
6. Search, filtering, and pagination.
7. Profile and settings pages, including the implemented theme and session/device features.
8. Responsive layouts for desktop and mobile browsers.
9. Database migrations, models, Eloquent relationships, factories, and appropriate seeders.
10. Automated tests covering the important functionality and security rules.
11. Verified prevention of the main N+1 query problems.
12. A README containing setup instructions, environment configuration, MySQL setup, migration and seeding commands, test commands, and development startup instructions.
13. A short architecture explanation describing how the web client communicates with Laravel and how the future Flutter client can use a JSON API and Sanctum.
14. A short explanation of the N+1 problem found in the project, the fix applied, and how it was verified.

At the end, report what was implemented, which tests were actually run, whether they passed, any remaining limitations, and the commands needed to start the project.

## Final instruction

Treat this as a learning-focused internship project. Make sound engineering decisions, but keep the solution proportionate to the requirements.

Do not silently skip requirements, add unrelated features, or pretend unfinished functionality is complete.

When a significant architectural decision is necessary, explain the decision briefly and proceed with the simplest conventional option unless clarification is genuinely required.

The result should be a working application that I can understand, maintain, demonstrate, and extend with a Flutter mobile client later.
