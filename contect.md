# Jobmate - Comprehensive Project Context & Technical Architecture

> **Document Name:** `contect.md`  
> **Project Name:** Jobmate (`jobmate`)  
> **Version:** `1.0.0+1`  
> **SDK:** Dart `^3.11.5` / Flutter SDK (Uses Material Design 3)  
> **Target Audience:** Developers, Technical Architects, Product Managers, and AI Pairing Agents  

---

## 1. Executive Summary & Product Vision

**Jobmate** is a specialized, production-grade on-demand work marketplace mobile application engineered with Flutter. It connects daily/blue-collar **Workers** looking for local opportunities with **Work Givers** (individuals, small business owners, and event managers) requiring flexible, reliable labor. In addition to the two primary consumer personas, Jobmate incorporates an integrated **Administrative Console** for platform governance, fraud prevention, user verification, job moderation, and dispute arbitration.

### Core Objectives:
- **Instant Local Employment**: Match verified workers with nearby daily jobs (retail, delivery, events, cleaning, construction, hospitality, office support, etc.).
- **Transparent Payouts & Escrow-style Settlement**: Clear breakdown of base pay, overtime, travel allowance, and food allowance, with instant release and receipt generation.
- **Physical Accountability**: Prevent unattended or unsupervised check-ins through an on-site, single-use 4-digit verification code system shared between the Work Giver and Worker.
- **Two-Way Trust & Safety**: In-depth profile verifications (Government ID, phone OTP, skills assessment, address), two-way star ratings/reviews, and an active dispute resolution pipeline.
- **Unified Native Experience**: Single codebase supporting role-specific UI themes (Worker Teal vs. Giver Purple vs. Admin Slate), dynamic navigation, and responsive typography.

---

## 2. Technology Stack & Technical Specifications

| Layer / Aspect | Technology / Library | Version / Detail |
| :--- | :--- | :--- |
| **Framework** | Flutter | Material 3 enabled |
| **Language** | Dart | `^3.11.5` (Modern syntax: records, patterns, switch expressions) |
| **State Management** | `provider` | `^6.1.2` (`ChangeNotifier`, `MultiProvider`, selector optimization) |
| **HTTP Transport** | `http` | `^1.6.0` (Cross-platform, web-compatible, uncoupled from `dart:io`) |
| **Persistence** | `shared_preferences` | `^2.5.5` (Session tokens, expiry timestamps, onboarding state) |
| **Internationalization** | `intl` | `^0.20.2` (Currency, relative dates, time formatting) |
| **Icons** | `cupertino_icons` | `^1.0.8` & `Icons.*` Material Icons |
| **Linting & Code Quality** | `flutter_lints` | `^6.0.0` with strict analysis options |
| **Backend Integration** | ASP.NET Web API | RESTful JSON API documented via OpenAPI / Swagger (`swagger.json`) |
| **API Scale** | 84 endpoints | Covering Auth, Profiles, Jobs, Applications, Assignments, Wallet, Admin |
| **Default Host** | `ApiConfig.baseUrl` | `http://10.84.31.59:5234` (Android emulator: `http://10.0.2.2:5234`) |

---

## 3. Architecture & Design Patterns

The project follows a clean **Layered Architecture** adhering strictly to SOLID principles, separation of concerns, and dependency inversion:

```
┌────────────────────────────────────────────────────────┐
│                        UI Layer                        │
│   (Screens, Shell Hosts, Shared & Feature Widgets)     │
└───────────────────────────▲────────────────────────────┘
                            │ listens via context.watch / context.select
┌───────────────────────────┴────────────────────────────┐
│                  Presentation / State                  │
│       (ChangeNotifier Providers & Flow Controllers)    │
└───────────────────────────▲────────────────────────────┘
                            │ delegates business operations
┌───────────────────────────┴────────────────────────────┐
│                   Domain & Service                     │
│    (Repository Interfaces, Business Enums, Models)     │
└───────────────────────────▲────────────────────────────┘
                            │ implemented by
┌───────────────────────────┴────────────────────────────┐
│                    Data & Transport                    │
│   (ApiClient, Wire Mappers, TokenStore, Fake Repos)    │
└────────────────────────────────────────────────────────┘
```

### Architectural Pillars:
1. **Repository Pattern with Composition Root (`AppRepositories`)**:
   - High-level modules and widgets depend entirely on abstract repository interfaces (`JobRepository`, `ApplicationRepository`, `UserRepository`, etc.).
   - Concrete implementations (`ApiJobRepository`, `ApiUserRepository`, etc.) handle network requests and JSON parsing.
   - For tests, `AppRepositories.custom(...)` injects in-memory mock repositories (`FakeUserRepository`, `FakeJobRepository`), allowing 100% of the UI and navigation logic to be tested without network dependencies.
2. **Provider State Tree (`providersFor`)**:
   - The provider graph is mounted at the root (`JobmateApp`), driven by the single `AppRepositories` instance.
   - Providers react to user session transitions cleanly (`_onAuthChanged` in `lib/app.dart` triggers coordinated data loading when transitioning to `AppStage.ready`).
3. **Stage-Driven Root Gate**:
   - Instead of fragmented conditional route jumps, authentication and onboarding state transitions are managed by an explicit stage machine (`AppStage`: `splash` → `onboarding` → `auth` → `profileSetup` → `ready`).
   - The initial route `AppRoutes.splash` renders `RootGate`, which reactively renders the appropriate screen based on `AuthProvider.stage`.
4. **Resilient HTTP Client (`ApiClient`)**:
   - Unwraps standard backend envelopes: `{ success, message, errorCode, data, pagination }`.
   - Single-flight token refresh mutex (`_refreshInFlight`) to eliminate race conditions when parallel requests hit `401 Unauthorized`.
   - Network failure abstraction: converts timeouts and dropped socket connections into user-friendly `ApiException` messages.
5. **Safe Typography & Accessibility**:
   - Text scaling protection implemented in `_AppView` using a linear scaler clamped between `0.9` and `1.3`. This accommodates user accessibility settings while avoiding layout overflows or assertion crashes in components like Material date pickers.

---

## 4. User Roles & Core Workflows

Jobmate distinguishes between three roles:

### 1. Worker Role (`UserRole.worker`)
- **Theme**: Teal Primary (`#0F766E`), Teal Secondary (`#14B8A6`), Mint Surface (`#E6F5F3`).
- **Discovery**: Real-time job search with rich filtering (category, location radius, pay range, schedule date, urgent flag), sorting (distance, pay, newest).
- **Application Flow**:
  - Apply with custom message, expected pay proposal, and availability confirmation.
  - Track live application status (`applied` → `viewed` → `shortlisted` → `accepted`).
  - Ability to withdraw pending applications before assignment.
- **On-the-Job Workflow (`AcceptedJobScreen`)**:
  - View job location, reporting time, contact person, dress code, safety rules.
  - **Check-in**: Worker inputs the 4-digit code provided on-site by the work giver to verify physical presence.
  - Mark job completed, report overtime hours worked.
- **Wallet & Earnings (`EarningsScreen`)**:
  - View total earned, pending clearance, and disputed amounts.
  - Monthly earnings breakdown and transaction history with receipts.
- **Reputation**: View overall rating score (stars) and feedback received from work givers.

### 2. Work Giver Role (`UserRole.workGiver`)
- **Theme**: Deep Purple Primary (`#7C3AED`), Light Purple Secondary (`#A78BFA`), Lavender Surface (`#F1EBFE`).
- **Job Creation Wizard (`CreateJobScreen`)**:
  - Six-step guided posting wizard:
    1. *Job Basics*: Title, category, description, worker count required.
    2. *Requirements*: Experience level, required skill tags.
    3. *Schedule*: Date, start time, end time, reporting time, break duration.
    4. *Payment*: Pay rate (hourly/daily/fixed/per piece), travel & food allowances, overtime rate, payment method.
    5. *Location*: Work address, area/neighborhood, location visibility toggle.
    6. *Contact & Safety*: On-site contact person, emergency phone, dress code, physical demands, safety gear details.
- **Hiring & Applicant Management (`JobApplicationsScreen`, `SelectWorkerScreen`)**:
  - View applicant profiles, experience, and verification badges.
  - Shortlist candidates, counter-propose pay, or reject applications.
  - Book single or bulk workers, which converts applications into confirmed `WorkerAssignment` entries.
- **On-Site Supervision**:
  - Generate and view the single-use 4-digit check-in code.
  - Send check-in reminder nudges to booked workers.
- **Payout & Settlement (`PaymentScreen`)**:
  - Calculate base pay, approved overtime, and platform service fee (5%).
  - Process payout via UPI, Bank Transfer, or Cash.
  - Idempotency key protection prevents duplicate charge requests.
- **Review Worker (`RateWorkerScreen`)**:
  - Submit 1–5 star ratings and written reviews upon job completion.

### 3. Administrator Console (`UserRole.admin`)
- **Theme**: Slate Dark Primary (`#1E293B`), Indigo Accent (`#4F46E5`), Light Indigo Surface (`#EEF0FB`).
- **Access**: Dedicated authentication portal (`admin@jobmate.in` / `AppRoutes.adminLogin`).
- **Console Modules (`AdminShellScreen`)**:
  - **Dashboard**: Real-time KPI cards (Total Users, Active Workers, Active Givers, Live Jobs, Pending Verifications, Open Disputes).
  - **User Moderation (`AdminUsersScreen`)**: Search users, filter by role/status, activate or deactivate accounts with required moderation reasons.
  - **Job Moderation (`AdminJobsScreen`)**: Audit all platform jobs, inspect descriptions and compensation, filter by category/status.
  - **Dispute Resolution (`AdminDisputesScreen`)**: Triage disputes, review evidence, mark under review, reject, or resolve with administrative findings.
  - **Trust & Verification Queue (`AdminVerificationsScreen`)**: Inspect submitted verification documents (identity, phone, email, skills, address) and approve or reject requests.
  - **Console Settings (`AdminSettingsScreen`)**: Audit logs, admin session management.

---

## 5. Screen & Feature Directory

### Authentication & Onboarding (`lib/features/auth/screens/`)
- `splash_screen.dart`: Animated entry splash showing the Jobmate brand and loader.
- `onboarding_screen.dart`: Visual carousel introducing workers and givers to platform features.
- `login_screen.dart`: Secure sign-in with phone/email and password, role redirection.
- `register_screen.dart`: Registration with role selection (Worker or Work Giver), phone, and email.
- `otp_screen.dart`: 4-digit SMS OTP verification with countdown timer and resend capability.
- `profile_setup_screen.dart`: Initial profile configuration (full name, location area, primary skills).
- `forgot_password_screen.dart`: Password recovery flow via phone verification code and password reset.

### Worker Features (`lib/features/worker/screens/`)
- `worker_home_screen.dart`: Worker dashboard showing stats, recommended jobs, nearby jobs, and quick actions.
- `search_jobs_screen.dart`: Real-time job search with filters for category, distance, pay, and date.
- `job_details_screen.dart`: Comprehensive job overview (allowances, location, timing, requirements, apply CTA).
- `apply_screen.dart`: Job application modal with message, availability, and pay expectations.
- `applications_screen.dart`: Worker application history across all lifecycle stages.
- `application_details_screen.dart`: Specific application status inspection and withdrawal options.
- `accepted_job_screen.dart`: Confirmed assignment console: reporting instructions, 4-digit check-in, completion flow.
- `earnings_screen.dart`: Financial wallet, payout statistics, monthly earnings cards, payment receipts.

### Work Giver Features (`lib/features/giver/screens/`)
- `giver_home_screen.dart`: Giver dashboard showing active job counts, pending applicant alerts, and fast job creation.
- `create_job_screen.dart`: 6-step job wizard with step validation, draft saving, and instant publishing.
- `my_jobs_screen.dart`: Management screen for all postings (Drafts, Active, In Progress, Completed, Cancelled).
- `job_applications_screen.dart`: Applicant pipeline for a specific job (Shortlist, Reject, Propose Pay).
- `select_worker_screen.dart`: Confirmation and booking screen for selected candidates.
- `payment_screen.dart`: Pay release console with platform fee deduction, overtime adjustments, and payment receipts.
- `rate_worker_screen.dart`: Performance review modal for workers after work completion.

### Common & Shared Features (`lib/features/common/screens/`)
- `chat_screen.dart`: Direct 1-to-1 conversation view between worker and giver with job context banner.
- `messages_screen.dart`: Inbox of all ongoing and archived conversation threads.
- `notifications_screen.dart`: Chronologically grouped notifications (Today, Yesterday, Earlier this week, Older).
- `profile_screen.dart`: User profile, verification badges, contact information, work history, and settings link.
- `verification_centre_screen.dart`: Status of identity, phone, email, skills, and address verifications.
- `work_history_screen.dart`: Verified historical jobs, dates, and ratings received.
- `settings_screen.dart`: Preferences, notification toggles, theme settings, terms, privacy, and sign out.
- `help_screen.dart`: Searchable help center and category-based FAQ articles.
- `contact_support_screen.dart`: Direct support phone, email, and live ticket submission.
- `report_problem_screen.dart`: Dispute and incident reporting form (unsafe conditions, non-payment, no-shows).

### Admin Features (`lib/features/admin/screens/`)
- `admin_login_screen.dart`: Administrative sign-in with email and security credentials.
- `admin_shell_screen.dart`: Bottom tab scaffold for the admin console.
- `admin_dashboard_screen.dart`: Platform metrics, health overview, and action queues.
- `admin_users_screen.dart`: User directory, role filtering, suspension/activation tools.
- `admin_jobs_screen.dart`: Global job audit and moderation list.
- `admin_disputes_screen.dart`: Dispute queue management and resolution workspace.
- `admin_verifications_screen.dart`: Document verification queue and review dialogs.
- `admin_settings_screen.dart`: Admin console preferences and logout.

---

## 6. Domain Entities & Data Models

All core data structures reside in `lib/models/`:

### Enums (`lib/models/enums.dart`)
- **`UserRole`**: `worker`, `workGiver`, `admin`
- **`JobStatus`**: `draft`, `pending`, `active`, `inProgress`, `completed`, `cancelled`, `expired`
- **`ApplicationStatus`**: `applied`, `viewed`, `shortlisted`, `accepted`, `rejected`, `withdrawn`, `expired`
- **`ApplicantStatus`**: `applied`, `shortlisted`, `rejected`, `selected`
- **`PaymentStatus`**: `pending`, `processing`, `paid`, `disputed`, `failed`, `refunded`, `cancelled`
- **`PaymentMethod`**: `upi`, `bank`, `cash`
- **`PayType`**: `fixed`, `hourly`, `daily`, `perPiece`
- **`JobCategory`**: `retail`, `events`, `delivery`, `cleaning`, `security`, `office`, `hospitality`, `construction`, `teaching`, `healthcare`, `itSupport`, `other`
- **`WorkplaceType`**: `onSite`, `remote`, `hybrid`
- **`JobType`**: `oneTime`, `recurring`
- **`WorkDay`**: `monday` through `sunday`
- **`NotificationType`**: `applicationUpdate`, `jobAccepted`, `jobShortlisted`, `payment`, `jobReminder`, `newApplicant`, `system`
- **`DisputeStatus`**: `open`, `underReview`, `resolved`, `rejected`
- **`ReportReason`**: `unsafeWorkplace`, `notPaid`, `abusiveBehaviour`, `fakeJob`, `noShow`, `other`
- **`VerificationStatus`**: `notVerified`, `pending`, `verified`, `rejected`
- **`VerificationType`**: `identity`, `phone`, `email`, `skills`, `address`

### Core Models
- **`UserProfile`** (`lib/models/user.dart`): User identity, role, phone, email, rating, jobs completed, skills list, area.
- **`Job` & `JobDraft`** (`lib/models/job.dart`, `job_draft.dart`): Comprehensive job specifications including compensation, schedule, address, required workers, and safety rules.
- **`JobApplication` & `WorkerAssignment`** (`lib/models/application.dart`): Application details, proposed rates, check-in timestamps, completion flags, and overtime tracking.
- **`Earning` & `PaymentReceipt`** (`lib/models/earning.dart`): Financial records, payment IDs, gross vs net pay, platform fees, and status.
- **`Conversation` & `Message`** (`lib/models/messaging.dart`): In-app chat threads, sender IDs, timestamps, read receipts, and job context metadata.
- **`Dispute` & `VerificationRequest`** (`lib/models/admin.dart`): Administrative case files, submitted documents, resolution notes, and audit timestamps.
- **`SupportReport` & `HelpArticle`** (`lib/models/support.dart`): User feedback, tickets, and knowledge base articles.

---

## 7. State Management & Provider Graph

Mounted in `JobmateApp` (`lib/app.dart`), the app uses 9 dedicated `ChangeNotifier` providers:

1. **`AuthProvider`**: Manages auth lifecycle (`AppStage`), current user session, sign in, sign up, OTP verification, password recovery, profile editing, and verification summary.
2. **`JobFeedProvider`**: Manages active job listings, keyword search, category/distance/pay filters, sort order, and bookmarked/saved jobs.
3. **`WorkerProvider`**: Drives worker-specific data: active applications, confirmed assignments, earnings history, and check-in actions.
4. **`GiverProvider`**: Drives work giver actions: job listings, 6-step creation wizard, candidate shortlisting/selection, and pay release.
5. **`ChatProvider`**: Handles conversation threads, active messaging, and unread counters.
6. **`NotificationProvider`**: Handles in-app alerts, unread counts, and chronological grouping.
7. **`SupportProvider`**: Manages help FAQs, support ticket submission, and contact details.
8. **`AdminProvider`**: Powers the admin console: metrics loading, user bans, job moderation, dispute closing, and verification approval.
9. **`NavigationState`**: Preserves active tab indices across role changes and back navigation.

---

## 8. Backend API & Networking (`swagger.json`)

The application interacts with an ASP.NET Web API backend defined in `swagger.json`.

### Communication Specifications:
- **Base URL**: Set in `lib/core/constants/app_config.dart` (`http://10.84.31.59:5234`).
- **HTTP Header Protocol**:
  - `Accept: application/json`
  - `Content-Type: application/json`
  - `Authorization: Bearer <accessToken>` (omitted for public endpoints)
- **Automatic Token Refresh**:
  - Intercepts `401 Unauthorized`.
  - Automatically invokes `/api/v1/auth/refresh` using the stored `refreshToken`.
  - Retries the original request seamlessly upon successful token refresh.
  - Broadcasts `onSessionExpired` if the refresh token is expired or invalid.
- **Key API Endpoint Groups (84 endpoints total)**:
  - `/api/v1/auth/*`: Registration, login, OTP verification, token refresh, password resets.
  - `/api/v1/profile/*`: Profile management, contact info, presence heartbeat.
  - `/api/v1/jobs/*`: Job CRUD, search, bookmarks, recommended/nearby queries.
  - `/api/v1/applications/*`: Worker job applications, applicant shortlisting, rejections, hiring.
  - `/api/v1/assignments/*`: Check-in verification (`/check-in`), completion (`/complete`).
  - `/api/v1/conversations/*`: Chat threads, message history, mark as read.
  - `/api/v1/notifications/*`: User notifications, unread badges.
  - `/api/v1/worker/earnings*`: Wallet balance, transaction logs, monthly summaries.
  - `/api/v1/admin/*`: Platform KPIs, user status overrides, dispute workflows, document reviews.

---

## 9. Design System & UI Architecture

### Color Palette (`lib/core/constants/app_colors.dart`)
- **Neutrals**: Background (`#F0F4F8`), Surface (`#FFFFFF`), Border (`#E2E8F0`), Text Primary (`#0F172A`), Text Secondary (`#64748B`).
- **Worker Theme**: Teal (`#0F766E`), Teal Light (`#14B8A6`), Mint Tint (`#E6F5F3`).
- **Work Giver Theme**: Purple (`#7C3AED`), Light Purple (`#A78BFA`), Lavender Tint (`#F1EBFE`).
- **Admin Theme**: Slate (`#1E293B`), Indigo Accent (`#4F46E5`), Slate Light (`#EEF0FB`).
- **Feedback Accents**: Success (`#10B981`), Warning (`#F59E0B`), Error (`#EF4444`), Info (`#0EA5E9`).

### Design Tokens & Layout Constants (`lib/core/constants/app_spacing.dart`)
- Standardized spacing scale: `xxs: 2`, `xs: 4`, `sm: 8`, `md: 12`, `lg: 16`, `xl: 20`, `xxl: 24`, `xxxl: 32`.
- Screen horizontal margin: `16.0`.
- Card corner radii: `sm: 8`, `md: 12`, `lg: 16`, `pill: 999`.

### Reusable Core UI Components (`lib/core/widgets/`)
- `AppCard`: Consistent elevated surfaces with soft shadows.
- `AppButton`: Primary, secondary, text, and destructive button styles with loading indicators.
- `AppTextField`: Standardized form inputs with floating labels, validation states, and icons.
- `AppTopBar`: Role-aware app bar with search, notification badge, and profile shortcuts.
- `AppBottomNav`: Animated bottom navigation bar with unread counters.
- `StatusChip`: Color-coded status badge for jobs, applications, payments, and verifications.
- `StatCard`: KPI metric cards used in worker earnings and admin dashboards.
- `StateViews`: Skeleton loaders (`SkeletonList`), empty state indicators (`EmptyStateView`), and retry error screens (`ErrorStateView`).
- `OtpInput`: Formatted 4-digit verification input with auto-advance.
- `ProfileAvatar`: Initials-based or image-based user avatar with verification badge.

---

## 10. Testing Infrastructure & Quality Assurance

Jobmate includes a comprehensive automated test suite in `test/`:

- **Complete Decoupling from Backend**: All widget and integration tests run against in-memory fakes located in `test/support/fake_data_layer.dart` (`FakeUserRepository`, `FakeJobRepository`, `FakeApplicationRepository`, etc.).
- **Deterministic Fixtures (`test/support/fixtures.dart`)**:
  - Pre-seeded accounts:
    - Worker: *Ravi Kumar* (`ravi@jobmate.in` / `jobmate123`), *Priya Nair*, *Amit Verma*.
    - Work Giver: *Aarav Malhotra* (`aarav@brightevents.in` / `jobmate123`), *Meera Shah*, *Deepak Rao*.
    - Admin: *Admin Console* (`admin@jobmate.in` / `admin123`).
  - Pre-configured jobs, applications, ratings, conversations, and disputes.
- **Test Files**:
  - `widget_test.dart`: Basic smoke and component mounting tests.
  - `app_flow_test.dart`: Complete onboarding, stage transitions, and sign-in to the worker shell.
  - `worker_flow_test.dart`: Worker job search, details inspection, application submission, and check-in flow.
  - `giver_flow_test.dart`: Work giver 6-step job creation, applicant shortlisting, and payment release.
  - `giver_login_test.dart`: Work giver credential validation and dashboard loading.
  - `admin_flow_test.dart`: Admin authentication, dashboard KPI verification, user moderation, and dispute triaging.
  - `navigation_test.dart`: Tab switching, deep link routes, and shell index preservation.
  - `common_flow_test.dart`: Messaging, notifications, help center, and profile settings.
  - `text_scale_test.dart`: Visual stability and assertion-free rendering across extreme font scale factors.

---

## 11. Directory & File Structure

```
c:\Visual Studio\Jobmate\
├── pubspec.yaml                     # Dependencies, assets & project metadata
├── swagger.json                     # Complete OpenAPI backend specification (84 endpoints)
├── README.md                        # Quickstart running and test commands
├── contect.md                       # This comprehensive project context document
├── lib\
│   ├── main.dart                    # Application entry point & service initialization
│   ├── app.dart                     # JobmateApp widget, provider tree & theme builder
│   ├── app\
│   │   └── theme\
│   │       └── app_theme.dart       # Material 3 Worker & Giver theme definitions
│   ├── core\
│   │   ├── constants\
│   │   │   ├── app_colors.dart      # Design token color definitions & shadows
│   │   │   ├── app_config.dart      # ApiConfig (baseUrl, defaultPageSize)
│   │   │   └── app_spacing.dart     # Spacing, padding & radius scales
│   │   ├── utils\
│   │   │   ├── context_extensions.dart  # Theme and media query helper extensions
│   │   │   ├── formatters.dart      # Currency (₹), date, and time formatting
│   │   │   └── validators.dart      # Email, phone, password, and OTP form validators
│   │   └── widgets\                 # Reusable UI component library
│   │       ├── app_bottom_nav.dart
│   │       ├── app_buttons.dart
│   │       ├── app_card.dart
│   │       ├── app_dialogs.dart
│   │       ├── app_text_field.dart
│   │       ├── app_top_bar.dart
│   │       ├── application_card.dart
│   │       ├── info_row.dart
│   │       ├── job_card.dart
│   │       ├── otp_input.dart
│   │       ├── profile_avatar.dart
│   │       ├── section_header.dart
│   │       ├── stat_card.dart
│   │       ├── state_views.dart
│   │       └── status_chip.dart
│   ├── features\
│   │   ├── admin\screens\           # Admin console screens (Dashboard, Users, Jobs, Disputes, Verify)
│   │   ├── auth\screens\            # Auth flow (Splash, Onboarding, Login, Register, OTP, Reset)
│   │   ├── common\screens\          # Shared screens (Chat, Notifications, Profile, Help, Settings)
│   │   ├── giver\screens\           # Work Giver screens (Create Job, My Jobs, Applicants, Payment)
│   │   ├── shell\                   # AppShell tab scaffold
│   │   └── worker\screens\          # Worker screens (Search, Job Details, Apply, Accepted, Earnings)
│   ├── models\                      # Domain models and business logic enums
│   │   ├── admin.dart
│   │   ├── application.dart
│   │   ├── earning.dart
│   │   ├── enums.dart
│   │   ├── job.dart
│   │   ├── job_draft.dart
│   │   ├── messaging.dart
│   │   ├── support.dart
│   │   └── user.dart
│   ├── navigation\
│   │   ├── app_router.dart          # Typed route constants and push helpers
│   │   ├── root_gate.dart           # Reactive stage gate
│   │   └── route_table.dart         # Named route generator map
│   ├── services\
│   │   ├── help_content.dart        # Static FAQ articles & help definitions
│   │   ├── service_locator.dart     # AppRepositories composition root
│   │   ├── api\                     # HTTP transport, wire mappers, tokens & exceptions
│   │   │   ├── api_client.dart
│   │   │   ├── api_exception.dart
│   │   │   ├── envelope.dart
│   │   │   ├── json.dart
│   │   │   ├── mappers.dart
│   │   │   ├── token_store.dart
│   │   │   └── wire.dart
│   │   └── repositories\            # Repository interfaces & API implementations
│   │       ├── admin_repository.dart
│   │       ├── application_repository.dart
│   │       ├── earning_repository.dart
│   │       ├── help_repository.dart
│   │       ├── job_repository.dart
│   │       ├── messaging_repository.dart
│   │       ├── notification_repository.dart
│   │       ├── user_repository.dart
│   │       └── api\                 # API-backed concrete repository implementations
│   └── state\                       # ChangeNotifier state providers
│       ├── admin_provider.dart
│       ├── auth_provider.dart
│       ├── chat_provider.dart
│       ├── giver_provider.dart
│       ├── job_feed_provider.dart
│       ├── navigation_state.dart
│       ├── notification_provider.dart
│       ├── support_provider.dart
│       └── worker_provider.dart
└── test\                            # Test suite & in-memory test doubles
    ├── admin_flow_test.dart
    ├── app_flow_test.dart
    ├── common_flow_test.dart
    ├── giver_flow_test.dart
    ├── giver_login_test.dart
    ├── navigation_test.dart
    ├── text_scale_test.dart
    ├── widget_test.dart
    ├── worker_flow_test.dart
    └── support\                     # In-memory fakes and fixtures
        ├── fake_backend.dart
        ├── fake_data_layer.dart
        └── fixtures.dart
```

---

## 12. Developer Quickstart & Commands

### Prerequisites
- Flutter SDK `3.11.5` or higher installed and on `PATH`.
- Android Studio / VS Code with Flutter and Dart extensions.
- Android Emulator or physical device.

### Running the App
```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run on connected device or emulator
flutter run
```

### Backend Configuration
- Configure the API address in `lib/core/constants/app_config.dart`:
  ```dart
  class ApiConfig {
    static const String baseUrl = 'http://10.84.31.59:5234'; // Default LAN host
    // For Android Emulator, use: 'http://10.0.2.2:5234'
  }
  ```
- *Note:* Plain HTTP is permitted during debug builds (`android:usesCleartextTraffic="true"` in debug manifest). Production/release builds enforce HTTPS endpoints.

### Executing Tests & Code Quality
```bash
# Run static analysis
flutter analyze

# Run the complete automated test suite
flutter test
```

### Seed Accounts for Manual Testing
- **Worker Account:** `ravi@jobmate.in` / Password: `jobmate123`
- **Work Giver Account:** `aarav@brightevents.in` / Password: `jobmate123`
- **Admin Console:** `admin@jobmate.in` / Password: `admin123`

