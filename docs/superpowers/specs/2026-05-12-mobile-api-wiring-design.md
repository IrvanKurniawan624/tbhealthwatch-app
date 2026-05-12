# Mobile API Wiring — Design Spec

**Date:** 2026-05-12  
**Issue:** #5 — Wire all available mobile screens to the live backend API  
**Scope:** Flutter mobile app (`mobile/lib/`) only. Backend is complete and merged on `main`.

---

## Context

The backend exposes JWT-authenticated REST endpoints at `http://localhost:5000/api` (Docker) / `http://10.0.2.2:5000/api` (Android emulator). All six built mobile screens currently use mock repositories. This spec describes the minimal changes needed to replace mocks with real API calls.

Demo credentials (seeded): `siti.aminah@tbhealthwatch.test` / `Demo123!`

---

## Architecture

### HTTP layer — `lib/core/api_client.dart`

A single class wrapping the existing `http` package. Responsibilities:

1. **Base URL** — configurable constant (`http://10.0.2.2:5000/api` default).
2. **Token storage** — reads/writes `accessToken` and `refreshToken` via `SharedPreferences`.
3. **Auth injection** — adds `Authorization: Bearer <accessToken>` to every request.
4. **401 handling** — on 401 response, calls `POST /api/auth/refresh`, persists new token pair, retries original request once. On second failure, clears stored tokens and throws `UnauthorizedException` so the UI can redirect to `LoginPage`.
5. **Convenience methods** — `get(path)`, `post(path, body)`, `put(path, body)` returning decoded `Map<String, dynamic>` or `List<dynamic>`.

Static helpers on `ApiClient`:
- `ApiClient.saveTokens(accessToken, refreshToken)` — used by login.
- `ApiClient.clearTokens()` — used by logout.
- `ApiClient.hasToken()` — returns `Future<bool>`, used by auth guard.

### Dependency injection

No DI framework. Repositories are instantiated where they're first used (inside `State.initState` or passed through constructors). A single shared `ApiClient` instance is created once per page tree that needs it.

### New package

Add `shared_preferences: ^2.3.0` to `pubspec.yaml`.

---

## Model Changes

### `lib/data/models/patient_model.dart`

Add nullable detail fields and serialization:

```dart
class Patient {
  // existing
  final String id;
  final String name;
  final String status;
  final String location;
  final String phase;
  final int currentMonth;
  final int totalMonths;
  // new (null when constructed from list endpoint)
  final String? nik;
  final String? phone;
  final String? address;
  final String? dob;       // ISO string "1989-08-17"
  final String? regionName;
  final String? photoUrl;

  factory Patient.fromJson(Map<String, dynamic> json) { ... }
}
```

### `lib/data/models/adherence_model.dart` (new)

```dart
class AdherenceSummary {
  final double percentage;
  final int target;
  final int dosesTaken;
  final int dosesTotal;
  final int streakDays;
  final String currentPhase;
}

class AdherenceDay {
  final String date;   // "2024-10-01"
  final String status; // taken | missed | partial | pending | upcoming | outside_month
}

class AdherenceCalendar {
  final int year;
  final int month;
  final List<AdherenceDay> days;
}
```

---

## Repository Changes

### `lib/data/repositories/api_profile_repository.dart`

Switch from raw `http` to `ApiClient`. No interface change.

### `lib/data/repositories/api_patient_repository.dart` (new)

Implements `IPatientRepository` plus two extra methods:

```dart
class ApiPatientRepository implements IPatientRepository {
  Future<List<Patient>> getMonitoringPatients();  // GET /patients
  Future<Patient> getById(String id);             // GET /patients/{id}
  Future<Patient> update(String id, Map<String,dynamic> data); // PUT /patients/{id}
}
```

### `lib/data/repositories/api_adherence_repository.dart` (new)

No interface (only one implementation):

```dart
class ApiAdherenceRepository {
  Future<AdherenceSummary> getSummary(String patientId);
  Future<AdherenceCalendar> getCalendar(String patientId, int year, int month);
  Future<void> log(String patientId, String logDate, String status, {String? notes});
}
```

---

## Screen-by-Screen Changes

### `main.dart` — auth guard

Replace `home: LoginPage()` with a `FutureBuilder` on `ApiClient.hasToken()`:
- `true` → `MonitoringPage()`
- `false` → `LoginPage()`

### `login_page.dart`

`_handleLogin()`:
1. Call `POST /api/auth/login` with `{email, password}`.
2. On success: call `ApiClient.saveTokens(...)`, navigate to `MonitoringPage`.
3. On failure: show error `SnackBar` ("Email atau password salah").
4. Show loading indicator while the request is in flight (disable button).

### `monitoring_page.dart`

- Replace `MockPatientRepository()` with `ApiPatientRepository(ApiClient())`.
- `_patientsFuture` type stays `Future<List<Patient>>` — no other changes.

### `patient_detail_page.dart`

Replace all hardcoded values with real data. The page already receives a `Patient` (list item) from the monitoring screen, so the `id` is available.

Load three futures concurrently:

```dart
Future.wait([
  _patientRepo.getById(widget.patient.id),
  _adherenceRepo.getSummary(widget.patient.id),
  _adherenceRepo.getCalendar(widget.patient.id, now.year, now.month),
])
```

Map API data to existing widgets:
- `patient.phone`, `patient.regionName`, `patient.dob` → header info section.
- `summary.percentage`, `summary.dosesTaken`, `summary.dosesTotal`, `summary.streakDays` → treatment target + stats.
- `calendar.days` → calendar grid (status string → cell color, see mapping below).
- "Catat Obat Sekarang" button → `_adherenceRepo.log(id, today, 'taken')`, show SnackBar on success.

**Calendar status → color mapping:**

| API `status` | Cell background | Badge |
|---|---|---|
| `taken` | `0xFFEBF5FF` | Blue ✓ |
| `missed` | `0xFFFFE4E6` | Red ✗ |
| `partial` | `0xFFFFF7E6` | Yellow ~ |
| `pending` | `0xFFF5F5F5` | None |
| `upcoming` | `0xFFF5F5F5` | None |
| `outside_month` | Transparent | None |

### `edit_patient_page.dart`

- Accept `Patient` with full detail fields (the detail already loaded in `PatientDetailPage`).
- Pre-fill: name from `patient.name`, dob from `patient.dob`, wilayah from `patient.regionName`, phone from `patient.phone`.
- Wire save button: call `ApiPatientRepository.update(patient.id, {...})`. Show SnackBar, pop on success.
- Remove hardcoded "Daffu" / "17 - agustus - 1945" / etc. placeholders.
- Load regions (`GET /api/regions`) on init — same pattern as `EditProfilePage` — to populate the wilayah dropdown and resolve `regionId` for the PUT payload.

### `profile_page.dart`

- Replace `MockProfileRepository()` with `ApiProfileRepository(ApiClient())`.
- Wire `LogoutButton.onPressed`: call `POST /api/auth/logout` → `ApiClient.clearTokens()` → `Navigator.pushAndRemoveUntil(LoginPage)`.

### `edit_profile_page.dart`

- On init, fetch regions: `GET /api/regions` → populate `_wilayahList` replacing the hardcoded 31-item list.
- Save path unchanged (`_doSave` already calls `repository.updateProfileData`).

---

## Error Handling

- **Network error / timeout**: show `SnackBar` with "Koneksi gagal, coba lagi".
- **401 after refresh fails**: `ApiClient` throws `UnauthorizedException`; catch in a top-level try/catch in each page's load method and navigate to `LoginPage`.
- **404 / other 4xx**: show `SnackBar` with the error message from the response body `message` field if present, otherwise a generic message.
- **Loading state**: FutureBuilder already shows `CircularProgressIndicator` during load — no changes needed for list/profile pages. `PatientDetailPage` will add a similar loading state for its `Future.wait`.

---

## Files Changed Summary

| File | Type |
|---|---|
| `pubspec.yaml` | Add `shared_preferences` |
| `lib/core/api_client.dart` | **NEW** |
| `lib/data/models/patient_model.dart` | Extend fields + add `fromJson` |
| `lib/data/models/adherence_model.dart` | **NEW** |
| `lib/data/repositories/api_profile_repository.dart` | Switch to `ApiClient` |
| `lib/data/repositories/api_patient_repository.dart` | **NEW** |
| `lib/data/repositories/api_adherence_repository.dart` | **NEW** |
| `lib/main.dart` | Auth guard |
| `lib/presentation/auth/login_page.dart` | Wire login |
| `lib/presentation/monitoring/monitoring_page.dart` | Swap mock |
| `lib/presentation/monitoring/patient_detail_page.dart` | Real data + calendar |
| `lib/presentation/monitoring/edit_patient_page.dart` | Pre-fill + save API |
| `lib/presentation/profile/profile_page.dart` | Swap mock + logout |
| `lib/presentation/profile/edit_profile_page.dart` | Regions from API |

---

## Out of Scope

- Register / forgot password screens (no screen exists yet)
- Surveillance and Tracing tabs (commented out)
- Notifications bell (empty handler)
- Add patient screen (no screen exists)
- Push notifications
