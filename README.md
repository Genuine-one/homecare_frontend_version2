# KLE HOMECARE — Flutter Frontend

Cross-platform Flutter application for the KLE HomeCare home healthcare platform.
Three user portals — **Patient**, **Nurse / Resource**, and **Admin** — running on Android, iOS, Web, and Windows.

---

## Table of Contents

- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [API Base URL Configuration](#api-base-url-configuration)
- [App Routes](#app-routes)
- [Features by Role](#features-by-role)
  - [Patient](#patient)
  - [Nurse / Resource](#nurse--resource)
  - [Admin](#admin)
- [Authentication Flow](#authentication-flow)
- [State Management](#state-management)
- [Architecture](#architecture)
- [Shared Widgets](#shared-widgets)
- [Assets & Fonts](#assets--fonts)
- [Build & Run](#build--run)

---

## Tech Stack

| Concern | Package | Version |
|---|---|---|
| State management | flutter_riverpod | ^2.5.0 |
| Navigation | go_router | ^13.0.0 |
| HTTP client | dio | ^5.4.0 |
| Secure token storage | flutter_secure_storage | ^9.0.0 |
| Persistent settings | shared_preferences | ^2.2.0 |
| Fonts | google_fonts | ^6.2.1 |
| Animations | flutter_animate | ^4.5.0 |
| Charts | fl_chart | ^0.69.0 |
| File picker | file_picker | ^8.1.4 |
| File save | path_provider | ^2.1.4 |
| Excel export | excel | ^4.0.6 |
| Image caching | cached_network_image | ^3.3.0 |
| Push notifications | firebase_messaging + flutter_local_notifications | ^15.1.3 / ^17.2.2 |
| Location | geolocator | ^13.0.4 |
| Internationalisation | intl | ^0.19.0 |
| Code gen | freezed + json_serializable + riverpod_generator | ^2.5.0 / ^6.8.0 / ^2.4.0 |

---

## Project Structure

```
kle_homecare_flutter/
├── lib/
│   ├── main.dart                              # App entry — loads API URL, fires up Firebase, runs app
│   ├── core/
│   │   ├── constants/
│   │   │   ├── api_constants.dart             # All endpoint paths + runtime base URL management
│   │   │   ├── app_colors.dart                # Brand colour palette and gradients
│   │   │   ├── app_strings.dart               # Static UI strings
│   │   │   └── belgaum_areas.dart             # Locality list for the Belgaum city picker
│   │   ├── network/
│   │   │   ├── dio_client.dart                # Dio singleton — interceptors, JWT injection, auto-refresh
│   │   │   └── api_service.dart               # Generic HTTP helpers (get/post/patch/delete/getBytes/postFormData)
│   │   └── utils/
│   │       ├── validators.dart                # Form field validators
│   │       ├── helpers.dart                   # friendlyError, date formatting, misc
│   │       ├── area_resolver.dart             # Reverse-geocode lat/lng → locality name
│   │       ├── excel_saver.dart               # Conditional file-save (web vs mobile)
│   │       └── web_geo.dart                   # Geolocation abstraction (web vs mobile)
│   ├── features/
│   │   ├── auth/
│   │   │   ├── domain/                        # UserEntity + abstract AuthRepository
│   │   │   ├── data/                          # UserModel + AuthRepositoryImpl (Dio)
│   │   │   └── presentation/
│   │   │       ├── providers/auth_provider.dart
│   │   │       └── screens/
│   │   │           ├── login_screen.dart       # Patient login (mobile + password)
│   │   │           ├── nurse_login_screen.dart # Nurse login (mobile + password)
│   │   │           ├── admin_login_screen.dart # Admin login (email + password)
│   │   │           ├── register_screen.dart    # Self-registration (patient / nurse)
│   │   │           └── forgot_password_screen.dart
│   │   ├── patient/
│   │   │   └── presentation/screens/
│   │   │       ├── patient_shell.dart          # Bottom-nav shell
│   │   │       ├── patient_dashboard.dart      # Request list + status filters
│   │   │       ├── request_service_screen.dart # New service request form
│   │   │       └── patient_request_detail_screen.dart  # Detail + vitals + payment + feedback
│   │   ├── nurse/
│   │   │   └── presentation/screens/
│   │   │       ├── nurse_shell.dart            # Tab shell (Alerts / Profile)
│   │   │       └── job_detail_screen.dart      # Job detail + status update + vital recording
│   │   └── admin/
│   │       └── presentation/
│   │           ├── screens/
│   │           │   ├── admin_shell.dart         # Sidebar (desktop) / bottom-nav (mobile) shell
│   │           │   ├── admin_home_tab.dart      # Dashboard — KPI cards + recent requests
│   │           │   ├── admin_nurses_tab.dart    # Resource management
│   │           │   ├── admin_services_tab.dart  # Service catalogue management
│   │           │   ├── admin_shift_roster_tab.dart   # Shift scheduling — grid + list views
│   │           │   ├── admin_analytics_tab.dart      # Time-series charts
│   │           │   ├── admin_mis_report_tab.dart     # MIS report + Excel export
│   │           │   └── admin_profile_tab.dart
│   │           ├── providers/
│   │           │   ├── shifts_provider.dart     # Roster state (ShiftsNotifier)
│   │           │   ├── nurses_provider.dart
│   │           │   └── ...
│   │           └── widgets/
│   │               ├── admin_shift_roster_grid.dart  # Excel-style resource × date grid
│   │               ├── admin_shift_roster_table.dart # Paginated list view
│   │               ├── admin_shift_upload_sheet.dart # Excel import bottom sheet
│   │               ├── admin_shift_assign_sheet.dart # Manual assignment bottom sheet
│   │               ├── admin_shift_schedule_sheet.dart  # Weekly schedule manager
│   │               └── admin_shift_master_sheet.dart    # Shift definition editor
│   ├── routes/
│   │   └── app_router.dart                    # GoRouter setup + role-based redirect guards
│   ├── services/
│   │   └── notification_service.dart          # Firebase Cloud Messaging setup
│   └── shared/
│       ├── screens/
│       │   └── server_settings_screen.dart    # Runtime API base URL editor
│       ├── storage/
│       │   └── secure_storage.dart            # FlutterSecureStorage wrapper
│       └── widgets/                           # Reusable UI components (see below)
├── assets/
│   ├── images/                                # kle_logo.png
│   ├── icons/
│   └── fonts/                                 # Poppins 400–800 (regular + italic)
├── android/
├── ios/
├── web/
├── windows/
├── pubspec.yaml
└── analysis_options.yaml
```

---

## Getting Started

### Prerequisites

- Flutter SDK 3.19+ (Dart ≥ 3.3.0)
- Android Studio / Xcode for mobile targets
- A running instance of the KLE HomeCare backend

### Install & Run

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run on your target platform
flutter run -d chrome          # Web
flutter run -d windows         # Windows desktop
flutter run -d android         # Android device / emulator
flutter run -d ios             # iOS device / simulator
```

---

## API Base URL Configuration

The base URL is **runtime-configurable** — no rebuild needed when switching between local dev, ngrok, and production.

**Defaults (in `api_constants.dart`):**

| Platform | Default |
|---|---|
| Windows / macOS / Linux desktop | `http://127.0.0.1:8000/api/v1` |
| Android / iOS / Web | `http://127.0.0.1:8001/api/v1` |

**Changing at runtime** — tap the server icon on any login screen to open the Server Settings screen, paste your URL, and save. The value persists across restarts via `SharedPreferences`.

Programmatically:
```dart
await ApiConstants.setBaseUrl('https://your-ngrok-url.ngrok-free.app/api/v1');
DioClient.instance.updateBaseUrl(ApiConstants.baseUrl);
```

---

## App Routes

Managed by `GoRouter` with role-based redirect guards. Unauthenticated users are always sent to `/login`.

| Path | Screen | Allowed role |
|---|---|---|
| `/login` | Patient login | — |
| `/register` | Self-registration | — |
| `/nurse-login` | Nurse login | — |
| `/admin-login` | Admin login | — |
| `/forgot-password?role=` | Password reset (OTP) | — |
| `/patient` | Patient dashboard shell | `patient` |
| `/patient/new-request` | New service request | `patient` |
| `/patient/requests/:id` | Request detail | `patient` |
| `/patient/notifications` | Notifications | `patient` |
| `/nurse` | Nurse job alerts shell | `nurse` |
| `/nurse/jobs/:id` | Job detail | `nurse` |
| `/nurse/notifications` | Notifications | `nurse` |
| `/admin` | Admin shell (all tabs) | `admin` |
| `/settings/server` | API URL editor | Any |

**Redirect logic:**
- Not logged in → `/login`
- Logged in on an auth page → own role's dashboard
- Wrong role for a route → own role's dashboard

---

## Features by Role

### Patient

- Register with name, email, mobile, address, and Belgaum locality picker
- Login with 10-digit mobile + password
- Submit service requests — service type, urgency level, date/time, location
- Track request lifecycle: pending → assigned → in-progress → completed
- View vital signs recorded by the assigned nurse
- Submit payment — UPI / cash / card; attach UTR or reference number
- Rate and comment on completed services
- In-app notifications for assignments and status changes
- Forgot-password OTP flow

### Nurse / Resource

- Login with 10-digit mobile + password
- View job alerts — assigned jobs with patient and service details
- Accept or reject assignments
- Update job status: start → complete
- Record vital signs (BP, pulse, temperature, SpO₂, weight, etc.)
- View shift schedule — today's shift, upcoming shifts, past history
- Mark attendance for own shifts
- Request a shift swap with another resource
- Toggle own availability status
- In-app notifications

### Admin

- Login with email + password (seeded account — not self-registered)
- **Dashboard** — KPI cards: total requests, active nurses, revenue, pending assignments
- **Resources** — create nurse accounts, edit profiles, toggle active/inactive, delete
- **Service catalogue** — create, edit, toggle, delete services and categories
- **Shift Roster** — full shift scheduling module:
  - Define shift codes with name, time range, and colour (Morning, Evening, Night, Full-day, etc.)
  - Create and manage weekly schedules (draft → publish → unpublish)
  - Assign shifts manually (one entry) or in bulk (resource × date range)
  - Upload a weekly Excel roster and auto-import — times are parsed from the sheet, shift codes are created automatically; upload summary shows succeeded / failed / duplicate rows
  - Roster Grid view — Excel-style resource × date grid spanning a 4-week window; supports hover-to-delete
  - Roster List view — paginated table with date, resource, shift, status, and attendance columns
  - Filters: week picker, date range, resource, status
  - Export current roster as flat Excel, grid-shaped Excel, or PDF
  - Download a blank Excel upload template pre-filled with the week's dates and live shift codes
  - Copy a previous week's roster to a new week
  - View and approve / reject resource shift-swap requests
  - Shift audit log for all scheduling changes
- **Analytics** — time-series charts (day / week / month / year / custom range)
- **MIS Report** — resource job/revenue breakdown + patient-service details; exportable to Excel
- **Payment management** — record and update payments, upload receipts (PDF/JPG/PNG, ≤ 10 MB)
- **Feedback summary** — overall ratings analytics, per-nurse breakdown

---

## Authentication Flow

```
Patient / Nurse Login
  ↓  POST /api/v1/auth/login  { mobile, password }
  ↓  { access_token, refresh_token, user }
  ↓  Stored in FlutterSecureStorage
  ↓  AuthNotifier → AsyncData(AuthState)
  ↓  GoRouter redirects to role dashboard

Admin Login
  ↓  POST /api/v1/auth/login  { email, password }
  ↓  (same flow)
```

**Automatic token refresh** — `DioClient` holds a Dio interceptor that catches `401` responses, calls `POST /api/v1/auth/refresh`, updates the stored access token, and retries the original request transparently.

**Role enforcement** — after login, the wrong role triggers an immediate logout and an error snackbar. GoRouter redirects enforce this on every navigation.

---

## State Management

The app uses **Riverpod `AsyncNotifier`** throughout.

| Provider | Purpose |
|---|---|
| `authProvider` | Login, logout, register, session restore |
| `shiftsProvider` | Roster assignments, grid data, shift masters, schedules, filters |
| `nursesProvider` | Resource list (used in assignment dropdowns) |
| Feature-level providers | Per-screen state for patient requests, nurse jobs, analytics, MIS, etc. |

`AuthState`:
```dart
class AuthState {
  final UserEntity? user;   // null = not authenticated
  final bool isLoading;
  final String? error;
}
```

`ShiftsState` (example of a richer provider state):
```dart
class ShiftsState {
  final List assignments;      // paginated list view
  final List gridAssignments;  // all entries in the active date window (grid view)
  final List shiftMasters;     // shift definitions
  final List schedules;        // weekly schedules
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? resourceId;
  final String? assignmentStatus;
  // … pagination, loading flags, error/success messages
}
```

---

## Architecture

Clean Architecture (domain → data → presentation) for `auth` and `patient`:

```
Presentation  (Riverpod providers + Flutter widgets)
      ↓
Domain        (pure Dart entities + abstract repository interfaces)
      ↓
Data          (Dio repository implementations + JSON models)
      ↓
API           (FastAPI backend)
```

`admin` and `nurse` features use a simplified direct-Dio approach (providers call `ApiService` directly) since those screens are read-heavy dashboards with minimal local business logic.

---

## Shared Widgets

All reusable components live in `lib/shared/widgets/`:

| Widget | Description |
|---|---|
| `AuthInputField` | Styled `TextFormField` — supports formatters, accent colour |
| `GradientButton` | CTA button with gradient fill, loading state, optional icon |
| `ErrorBanner` | Inline error card |
| `KpiCard` | Dashboard stat tile (icon, value, label, accent colour) |
| `StatusBadge` | Coloured chip for request / assignment status |
| `PaginationBar` | Previous / Next page controls |
| `SectionHeader` | Section title with accent bar |
| `KleAppBar` | Branded app bar (used on mobile; desktop uses the sidebar header) |
| `ErrorView` | Full-area error state with retry button |
| `MobileWebFrame` | Constrains mobile-first screens to 480 px on wide web viewports |
| `SheetHandle` | Drag handle for bottom sheets |
| `TrialNoticeDialog` | One-time notice shown after first login |
| `LoginBackgroundBubble` | Decorative circle for login screen backgrounds |
| `LoginFeatureTile` | Feature highlight row for the login left panel (desktop) |
| `LoginLogoBadge` | Circular logo container for mobile login headers |

---

## Assets & Fonts

**Images** (`assets/images/`):
- `kle_logo.png` — primary logo, also used as the app launcher icon

**Fonts** (`assets/fonts/`):
- **Poppins** — weights 400, 500, 600, 700, 800 (regular + italic for each)

**Icons** (`assets/icons/`):
- Custom icon assets

---

## Build & Run

```bash
# Debug
flutter run

# Release APK (Android)
flutter build apk --release

# Release App Bundle (Android — for Play Store)
flutter build appbundle --release

# iOS (requires macOS + Xcode)
flutter build ios --release

# Web
flutter build web --release

# Windows
flutter build windows --release
```

**Launcher icons** (regenerate after changing `kle_logo.png`):
```bash
dart run flutter_launcher_icons
```

**Code generation** (freezed / json_serializable / riverpod_generator):
```bash
dart run build_runner build --delete-conflicting-outputs
```
