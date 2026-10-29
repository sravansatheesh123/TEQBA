# REBS HRMS — Offline-Capable Employee Workspace
> **Flutter Developer Assignment Submission**  
> An enterprise-grade Employee Attendance & Leave Management application built with Flutter, GetX Clean Architecture, Dio HTTP Client, Hive Offline Persistence, and Geolocator GPS Geofencing.

---

## 📑 Table of Contents
1. [Key Features Overview](#-key-features-overview)
2. [Architecture & Folder Structure](#-architecture--folder-structure)
3. [Offline Storage & Synchronization Strategy](#-offline-storage--synchronization-strategy)
4. [Event Identity & Idempotency Engine](#-event-identity--idempotency-engine)
5. [Attendance & GPS Geofencing (200m Rule)](#-attendance--gps-geofencing-200m-rule)
6. [Leave Management & Validation Rules](#-leave-management--validation-rules)
7. [Reviewer Simulation Tool & Mock Scenarios](#-reviewer-simulation-tool--mock-scenarios)
8. [Automated Test Suite](#-automated-test-suite)
9. [Deliverables & APK Instructions](#-deliverables--apk-instructions)
10. [Engineering Decisions, Assumptions & Trade-offs](#-engineering-decisions-assumptions--trade-offs)

---

## 🌟 Key Features Overview

* **Corporate Authentication & Login Screen**:
  - **Pre-configured Test Credentials**: Pre-loaded with requested credentials:
    - **Username / Employee ID**: `intest@123`
    - **Password**: `123456`
  - **One-Tap Quick Fill**: Dedicated "Auto Fill" card allowing reviewers to instantly test or manually input credentials.
  - **Validation & Error Handling**: Rejects invalid IDs or passwords with visual banners and error feedback.
  - **Persistent Session & Remember Me**: Login state is stored in Hive offline storage (`keyIsLoggedIn`), keeping the employee authenticated across app restarts.
  - **Sign Out Action**: Logout button available on Dashboard with confirmation dialog, seamlessly routing back to the Login screen.
  - **Theme Aware**: Supports Light Mode, Dark Mode, and Dark Eye Comfort mode directly from the Login AppBar.
* **Employee Dashboard**:
  - **Employee Profile Card with Direct Theme Helper Access**: Tapping anywhere on the employee profile header or avatar opens the **Theme & Display Helper** sheet directly. It also features a real-time visual badge displaying the active theme (`Light`, `Dark`, or `Comfort`).
  - Real-time attendance status (`Not Checked In`, `Checked In`, `Shift Completed`).
  - Dynamic live working duration timer ticking every second during an active shift.
  - **Live Current GPS Location Card**: Automatically fetches device coordinates (`Lat/Lng`), evaluates distance to the configured company office, and displays live within/outside geofence status directly on the dashboard.
  - Manual Location Refresh icon button to re-fetch live device coordinates on demand.
  - Quick Check-in and check-out timestamps.
  - Available leave balances (Casual and Sick leave breakdown).
  - Responsive offline banner with manual "Sync Now" trigger.
* **Theme & Display Helper (Light, Dark, and Dark Eye Comfort Modes)**:
  - Accessible directly by tapping the Employee Profile card or the palette icon in the top AppBar.
  - **Light Mode**: Crisp, high-contrast daytime workspace with clean white cards and royal blue accents.
  - **Dark Mode**: Deep midnight slate theme. Reduces screen glare & power consumption in dim lighting.
  - **Dark Eye Comfort Mode**: Warm espresso (`#181512`) and amber (`#F59E0B`) night shield designed to eliminate harsh blue-light strain during evening and night shifts.
  - Reactive instant live preview + persistent state saved across app restarts using Hive storage.
* **Attendance Screen & Check-In / Check-Out Engine**:
  - **GPS Geofence Verification**: Shows live coordinates, exact distance to office, and real-time within/outside 200m radius indicator.
  - **Seamless Outside Geofence Resolution**: If the user or reviewer is testing outside the 200m office area (e.g. at home or on emulator), the app displays an actionable helper offering **"Simulate Office Desk (0m)"** or **"Set My GPS as Office"** with 1-tap resolution.
  - **One Check-In Per Working Day**: Prevents accidental repeated check-ins with clear informative feedback.
  - **Sequential Check-Out Validation**: Check-out is permitted only after check-in has been recorded.
  - **Reset Attendance for Testing**: Includes a dedicated "Reset Attendance (Test Again)" button directly in the status card and AppBar, allowing reviewers to reset today's record back to `Not Checked In` and test the entire check-in and check-out flow as many times as desired.
  - **Bidirectional Dashboard Synchronization**: Marking Check-In or Check-Out immediately updates the Dashboard digital timer, punch cards, and action buttons without requiring manual page reloads.
  - **Debounced Action Buttons**: Guards against repeated rapid taps.
  - **Offline Resilience & Optimistic UI**: Immediately updates state locally and queues event in Hive when network is degraded or offline.
* **Attendance History Screen**:
  - Complete history log with horizontally scrollable filter chips (`All`, `Synced`, `Pending`, `Rejected`).
  - Date, check-in time, check-out time, working duration, and rejection reason display.
  - Pull-to-refresh and persistent offline cache.
* **Leave Application**:
  - Leave type selection: Casual Leave vs Sick Leave.
  - Date picker range with start date constraint (cannot be in the past) and end date constraint.
  - Live character counter verifying a minimum of 10 non-whitespace characters in reason.
  - Balance validation preventing requested days from exceeding remaining allowance.
  - Overlap detector preventing dates that conflict with existing Pending or Approved requests.
* **Leave History**:
  - Displays submitted applications with real-time status badges (`Pending`, `Approved`, `Rejected`).
  - Persistent offline viewing of loaded requests.
* **Reviewer Simulation Panel**:
  - Floating bottom sheet accessible directly from the app bar (`Science` icon) on any screen.
  - Streamlined office simulation options:
    - **Current Location (Device GPS)** (Default: fetches real-time device hardware GPS coordinates)
    - **Office Desk (0m away - Valid)** (< 200m geofence)
  - Beautiful, attractive **Submit & Apply Simulation** button with gradient styling, instant visual confirmation snackbar, and persistent state.

---

## 🏛️ Architecture & Folder Structure

The project strictly follows a **GetX Clean Architecture** pattern, enforcing separation of concerns between presentation, business logic, API access, and local persistence.

```
lib/
├── app/
│   ├── bindings/
│   │   └── initial_binding.dart          # Core DI registration
│   ├── routes/
│   │   ├── app_pages.dart                # GetPage route definitions
│   │   └── app_routes.dart               # Route constant strings
│   └── theme/
│       ├── app_colors.dart               # Enterprise HRMS color palette
│       └── app_theme.dart                # Material 3 theme & GoogleFonts Inter
├── core/
│   ├── constants/
│   │   ├── api_endpoints.dart            # REBS REST API endpoint constants
│   │   └── app_constants.dart            # Geofence coordinates & Hive box keys
│   ├── network/
│   │   ├── api_client.dart               # Dio HTTP client wrapper
│   │   ├── mock_api_interceptor.dart     # Mock API simulation engine
│   │   └── mock_scenario.dart            # Repeatable test scenarios enum
│   └── services/
│       ├── connectivity_service.dart     # Network monitor & reconnect hook
│       ├── location_service.dart         # GPS, distance calculation & presets
│       ├── storage_service.dart          # Hive persistent storage
│       └── sync_service.dart             # FIFO sync queue & idempotency handler
├── data/
│   ├── datasources/
│   │   ├── local/
│   │   │   └── app_local_datasource.dart # Hive box read/write operations
│   │   └── remote/
│   │       └── app_remote_datasource.dart# Dio API network calls
│   ├── models/
│   │   ├── attendance_event_model.dart   # UUID event, timestamp & sync status
│   │   ├── attendance_record_model.dart  # Daily log & duration helper
│   │   ├── employee_model.dart           # Employee profile & office config
│   │   ├── leave_balance_model.dart      # Casual and Sick balance tracking
│   │   ├── leave_request_model.dart      # Leave application & overlap logic
│   │   └── office_config_model.dart      # Office lat/lng & radius
│   └── repositories/
│       ├── attendance_repository.dart    # Attendance rules & offline queueing
│       ├── employee_repository.dart      # Profile caching & retrieval
│       └── leave_repository.dart         # Leave submission & validations
├── modules/
│   ├── attendance/                       # Check-in / Check-out screen
│   ├── dashboard/                        # Employee dashboard screen
│   ├── dev_tools/                        # Reviewer simulation panel
│   ├── history/                          # Attendance history screen
│   └── leave/                            # Leave application & history
└── main.dart                             # App initialization & Hive setup
```

---

## 🔄 Offline Storage & Synchronization Strategy

The offline sync architecture is designed to handle unreliable network environments seamlessly:

1. **Local Persistent Storage (Hive)**:
   - When an employee marks attendance while offline (or during a server timeout), the action is immediately saved to the `rebs_sync_queue_box` with status `Pending Sync`.
   - The daily record in `rebs_attendance_box` is optimistically updated with `Pending Sync`, giving the user immediate visual confirmation that their attendance has been safely logged.
   - When the app is closed, terminated, or reopened, pending events remain intact in Hive.

2. **FIFO Sequential Synchronization**:
   - The queue is sorted ascending by event timestamp: Check-in events are **always** synced before check-out events, preserving state integrity on the server.
   - If a transient network failure occurs midway, the sync loop pauses to prevent out-of-order execution.

3. **Automatic Reconnection Sync**:
   - `ConnectivityService` listens to network state changes via `connectivity_plus`.
   - When connectivity is restored, the `onConnectionRestored` hook automatically triggers `syncPendingQueue()`.
   - Users can also tap the manual **Sync Now** button at any time.

4. **Reconciliation & Conflict Handling**:
   - If the server returns **409 Conflict** (indicating that attendance was already committed, e.g. from an earlier request where the client timed out before receiving the acknowledgment), the client reconciles the state and marks the local record as `Synced`.
   - If a permanent client error occurs (400 Bad Request), the event is removed from the queue and flagged with `SyncStatus.rejected` along with the server's rejection reason.

---

## 🔑 Event Identity & Idempotency Engine

Network requests can time out after the server has processed them, causing clients to retry. To guarantee that retries **never produce duplicate records**:

- Every attendance action is assigned a client-generated **UUID v4** (`eventId`).
- The `POST /attendance/events` endpoint inspects the `eventId`:
  - If the `eventId` is new: The event is processed, written to the database, and `eventId` is recorded in the server's processed set.
  - If the `eventId` was already processed: The server returns `200 OK` with `{ "status": "idempotent_duplicate", "eventId": ... }` along with the existing record. No second attendance session is created.

---

## 📍 Attendance & GPS Geofencing (200m Rule)

- **Default Office Location**: REBS Tech Hub Bengaluru (`12.9715987° N, 77.5945627° E`).
- **Geofence Radius**: Exactly **200 metres**.
- Distance is computed via the geodesic Great-Circle formula using `Geolocator.distanceBetween(...)`.
- **Validation Rules**:
  1. An employee can check in once per working day.
  2. Check-out is permitted only after check-in.
  3. Outside Area Message: `"You are [X]m away from the office. Check-in is permitted only within 200m."`
  4. Location Permissions: Gracefully handles `denied`, `deniedForever`, and `locationServicesDisabled` with actionable prompts.

### Which checks must a production server repeat?
Device-side validation offers immediate feedback and low latency, but a production server **must repeat**:
1. **Server-side Geofencing & Mock Location Detection**: Verify GPS coordinates, accuracy circle, and check whether mock provider flags were set by device.
2. **Shift & Date Verification**: Verify check-in timestamp against company timezone (preventing client clock manipulation).
3. **One Check-in Per Day Rule**: Check database records for existing attendance on the company work day.
4. **Sequential State Enforcement**: Reject any check-out event where no matching active check-in exists.

---

## 📝 Leave Management & Validation Rules

- **Leave Types**: Casual Leave & Sick Leave.
- **Rule Validations**:
  1. **Start date** cannot be in the past.
  2. **End date** cannot precede start date.
  3. **Reason** must contain at least **10 non-whitespace characters** (enforced with live counter).
  4. **Balance Check**: Requested days cannot exceed remaining casual/sick allowance.
  5. **Overlap Check**: Dates cannot overlap any existing `Pending` or `Approved` request.
- **Offline Behavior**:
  - Submitting a new leave application requires active connectivity. If offline, the user is notified.
  - Previously loaded leave requests and leave balances are cached in Hive and remain fully viewable offline.

---

## 🧪 Reviewer Simulation Tool

To enable effortless verification without needing external mock GPS apps or proxy tools:

1. Tap the **Flask / Science icon** in the top AppBar of any screen to open the streamlined **Reviewer Simulation Panel**.
2. **Simplified Office Location Presets**:
   - **Current Location (Device GPS)**: Fetches real-time GPS coordinates directly from your physical/emulator device hardware (Default mode).
   - **Office Desk (0m away)**: Simulates sitting directly at the office desk. Exactly 0m from company location (< 200m valid zone).
3. **Submit & Apply Simulation**:
   - Tap the attractive gradient **"Submit & Apply Simulation"** button at the bottom to apply the selected mode instantly with feedback notification.

---

## 🧪 Automated Test Suite

All 22 tests are automated and passing:

| # | Test Name | Target File | Status |
|---|-----------|-------------|--------|
| 1 | Check-out without check-in is rejected | `test/unit/attendance_test.dart` | ✅ Passed |
| 2 | Repeated submission does not create duplicate attendance (Idempotency) | `test/unit/attendance_test.dart` | ✅ Passed |
| 3 | Overlapping leave dates are rejected | `test/unit/leave_test.dart` | ✅ Passed |
| 4 | Leave reason with less than 10 non-whitespace characters is rejected | `test/unit/leave_test.dart` | ✅ Passed |
| 5 | Default assigned test credentials match intest@123 and 123456 | `test/unit/login_test.dart` | ✅ Passed |
| 6 | Empty username shows validation error | `test/unit/login_test.dart` | ✅ Passed |
| 7 | Empty password shows validation error | `test/unit/login_test.dart` | ✅ Passed |
| 8 | Invalid credentials reject login with error message | `test/unit/login_test.dart` | ✅ Passed |
| 9 | Correct credentials (intest@123 & 123456) succeed and persist session | `test/unit/login_test.dart` | ✅ Passed |
| 10 | fillDemoCredentials resets username to intest@123 and password to 123456 | `test/unit/login_test.dart` | ✅ Passed |
| 11 | Logout clears the persistent login session | `test/unit/login_test.dart` | ✅ Passed |
| 12 | Default office location matches Bengaluru HQ | `test/unit/ride_location_test.dart` | ✅ Passed |
| 13 | Saving custom office coordinates persists in storage and updates reactive state | `test/unit/ride_location_test.dart` | ✅ Passed |
| 14 | Simulation modes evaluate geofence against active company location | `test/unit/ride_location_test.dart` | ✅ Passed |
| 15 | Pickup location acquires valid device coordinates for location card | `test/unit/ride_location_test.dart` | ✅ Passed |
| 16 | Default mode is Light Mode with crisp workspace colors | `test/unit/theme_helper_test.dart` | ✅ Passed |
| 17 | Switching to Dark Mode activates Midnight Slate theme | `test/unit/theme_helper_test.dart` | ✅ Passed |
| 18 | Switching to Dark Eye Comfort Mode activates Warm Amber shield | `test/unit/theme_helper_test.dart` | ✅ Passed |
| 19 | New ThemeService instance automatically restores persisted theme mode | `test/unit/theme_helper_test.dart` | ✅ Passed |
| 20 | ThemeHelper static facade delegates correctly to active ThemeService | `test/unit/theme_helper_test.dart` | ✅ Passed |
| 21 | Widget test covering Pending Sync & Offline banner states | `test/widget_test.dart` | ✅ Passed |
| 22 | Pending attendance survives persistence and syncs in FIFO order | `test/unit/attendance_test.dart` | ✅ Passed |

Run tests via terminal:
```bash
flutter test
```

---

## 📦 Deliverables & APK Instructions

- **Source Code**: Complete Git repository with null-safe Dart 3.
- **Installable Debug APK**: Located at:
  ```
  build/app/outputs/flutter-apk/app-debug.apk
  ```
- **How to Build Locally**:
  ```bash
  flutter pub get
  flutter test
  flutter run
  ```

---

## 💡 Engineering Decisions, Assumptions & Trade-offs

1. **State Management (GetX)**:
   - Selected for clean reactive programming (`.obs`), modular controllers, dependency injection via `Bindings`, and lightweight route navigation without boilerplate.
2. **Offline Storage (Hive)**:
   - Chosen over SQLite for ultra-fast key-value document storage, zero native compilation overhead, and reliable performance on Android/iOS.
3. **Mock HTTP Engine (Dio Interceptor)**:
   - Instead of hardcoding responses inside widgets, all requests flow through a Dio HTTP Client with configured timeouts and headers. The `MockApiInterceptor` acts as an in-process local mock server with scenario toggles and idempotency tracking.
4. **Timezone**:
   - Company timezone defaults to `Asia/Kolkata` (`IST`). Calendar day arithmetic normalizes dates to midnight to ensure accurate overlap detection.
5. **Effort & Time Spent**:
   - Architecture & Core Design System: 1.5 hours
   - Mock API & Idempotent Engine: 1.5 hours
   - Offline Queue & Sync Service: 2.0 hours
   - UI Screens & Reviewer Simulation Panel: 2.0 hours
   - Automated Unit & Widget Tests: 1.0 hour
   - **Total Time Spent**: ~8 hours
