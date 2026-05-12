# Mobile API Wiring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace all mock repositories in the Flutter app with real API calls to the live backend, wiring all 6 built screens end-to-end.

**Architecture:** A single `ApiClient` class wraps `http`, reads/writes tokens via `SharedPreferences`, injects `Authorization: Bearer` on every request, and handles 401 → refresh → retry. Repositories are constructor-injected with this client. No state management library added — existing `FutureBuilder` pattern is preserved throughout.

**Tech Stack:** Flutter (Dart), `http ^1.2.0` (already installed), `shared_preferences ^2.3.0` (to add), backend at `http://10.0.2.2:5000/api` (Android emulator) / `http://localhost:5000/api` (web/desktop).

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `mobile/pubspec.yaml` | Modify | Add `shared_preferences` dependency |
| `mobile/lib/core/api_client.dart` | **Create** | Token storage, auth injection, 401/refresh logic |
| `mobile/lib/data/models/patient_model.dart` | Modify | Add nullable detail fields + `fromJson` |
| `mobile/lib/data/models/profile_model.dart` | Modify | Fix `fromJson`/`toJson` key mapping for backend + add `regionId` |
| `mobile/lib/data/models/adherence_model.dart` | **Create** | `AdherenceSummary`, `AdherenceDay`, `AdherenceCalendar` models |
| `mobile/lib/data/repositories/api_patient_repository.dart` | **Create** | `list`, `getById`, `update` via `ApiClient` |
| `mobile/lib/data/repositories/api_adherence_repository.dart` | **Create** | `getSummary`, `getCalendar`, `log` via `ApiClient` |
| `mobile/lib/data/repositories/api_profile_repository.dart` | Modify | Switch raw `http` → `ApiClient` |
| `mobile/lib/main.dart` | Modify | Auth guard on startup |
| `mobile/lib/presentation/auth/login_page.dart` | Modify | Wire login, loading state, error SnackBar |
| `mobile/lib/presentation/monitoring/monitoring_page.dart` | Modify | Swap mock → `ApiPatientRepository` |
| `mobile/lib/presentation/monitoring/patient_detail_page.dart` | Modify | Load real detail + adherence, live calendar |
| `mobile/lib/presentation/monitoring/edit_patient_page.dart` | Modify | Pre-fill from patient, load regions, wire save |
| `mobile/lib/presentation/profile/profile_page.dart` | Modify | Swap mock → `ApiProfileRepository`, wire logout |
| `mobile/lib/presentation/profile/edit_profile_page.dart` | Modify | Load regions from API instead of hardcoded list |
| `mobile/test/models/patient_model_test.dart` | **Create** | `fromJson` unit tests |
| `mobile/test/models/adherence_model_test.dart` | **Create** | `fromJson` unit tests |

---

## Task 1: Create branch + add shared_preferences

**Files:**
- Modify: `mobile/pubspec.yaml`

- [ ] **Step 1.1: Create feature branch**

```bash
cd Z:\project\tbhealthwatch-app
git checkout -b feature/mobile-api-wiring
```

- [ ] **Step 1.2: Add shared_preferences to pubspec.yaml**

Open `mobile/pubspec.yaml`. Replace the `dependencies:` block with:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  http: ^1.2.0
  shared_preferences: ^2.3.0
```

- [ ] **Step 1.3: Install**

```bash
cd mobile
flutter pub get
```

Expected: `Got dependencies!` with no errors.

- [ ] **Step 1.4: Commit**

```bash
cd ..
git add mobile/pubspec.yaml mobile/pubspec.lock
git commit -m "chore(mobile): add shared_preferences dependency"
```

---

## Task 2: Create ApiClient

**Files:**
- Create: `mobile/lib/core/api_client.dart`

- [ ] **Step 2.1: Write the failing test**

Create `mobile/test/core/api_client_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projekakhir/core/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('hasToken returns false when no token stored', () async {
    expect(await ApiClient.hasToken(), false);
  });

  test('hasToken returns true after saveTokens', () async {
    await ApiClient.saveTokens('access123', 'refresh456');
    expect(await ApiClient.hasToken(), true);
  });

  test('clearTokens removes stored tokens', () async {
    await ApiClient.saveTokens('access123', 'refresh456');
    await ApiClient.clearTokens();
    expect(await ApiClient.hasToken(), false);
  });
}
```

- [ ] **Step 2.2: Run test to verify it fails**

```bash
cd mobile
flutter test test/core/api_client_test.dart
```

Expected: FAIL — `ApiClient` class not found.

- [ ] **Step 2.3: Create `lib/core/api_client.dart`**

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException([this.message = 'Sesi habis. Silakan login ulang.']);
}

class ApiClient {
  static const String _baseUrl = 'http://10.0.2.2:5000/api';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  // --- Token storage (static helpers used by login/logout screens) -----------

  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  static Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  // --- Private token read ---------------------------------------------------

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // --- Public HTTP methods --------------------------------------------------

  Future<dynamic> get(String path) => _request('GET', path);

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      _request('POST', path, body);

  Future<dynamic> put(String path, Map<String, dynamic> body) =>
      _request('PUT', path, body);

  // --- Core request logic ---------------------------------------------------

  Future<dynamic> _request(String method, String path,
      [Map<String, dynamic>? body]) async {
    final token = await _getAccessToken();
    var response = await _execute(method, path, body, token);

    if (response.statusCode == 401) {
      final newToken = await _tryRefresh();
      if (newToken == null) {
        await clearTokens();
        throw const UnauthorizedException();
      }
      response = await _execute(method, path, body, newToken);
      if (response.statusCode == 401) {
        await clearTokens();
        throw const UnauthorizedException();
      }
    }

    return _decode(response);
  }

  Future<http.Response> _execute(
      String method, String path, Map<String, dynamic>? body, String? token) {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final encoded = body != null ? jsonEncode(body) : null;

    switch (method) {
      case 'GET':
        return http.get(uri, headers: headers);
      case 'POST':
        return http.post(uri, headers: headers, body: encoded);
      case 'PUT':
        return http.put(uri, headers: headers, body: encoded);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  Future<String?> _tryRefresh() async {
    final refreshToken = await _getRefreshToken();
    if (refreshToken == null) return null;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newAccess = data['accessToken'] as String;
        final newRefresh = data['refreshToken'] as String;
        await saveTokens(newAccess, newRefresh);
        return newAccess;
      }
    } catch (_) {}
    return null;
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    throw Exception(_extractMessage(response.body));
  }

  String _extractMessage(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['message'] as String? ?? 'Terjadi kesalahan';
    } catch (_) {
      return 'Terjadi kesalahan';
    }
  }
}
```

- [ ] **Step 2.4: Run test to verify it passes**

```bash
flutter test test/core/api_client_test.dart
```

Expected: All 3 tests PASS.

- [ ] **Step 2.5: Commit**

```bash
cd ..
git add mobile/lib/core/api_client.dart mobile/test/core/api_client_test.dart
git commit -m "feat(mobile): add ApiClient with token storage and 401/refresh logic"
```

---

## Task 3: Extend Patient model + add adherence models

**Files:**
- Modify: `mobile/lib/data/models/patient_model.dart`
- Create: `mobile/lib/data/models/adherence_model.dart`
- Create: `mobile/test/models/patient_model_test.dart`
- Create: `mobile/test/models/adherence_model_test.dart`

- [ ] **Step 3.1: Write failing tests**

Create `mobile/test/models/patient_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:projekakhir/data/models/patient_model.dart';

void main() {
  test('Patient.fromJson parses list-endpoint fields', () {
    final json = {
      'id': 'abc-123',
      'nik': '3578010000000001',
      'name': 'Siti Aminah',
      'status': 'DALAM PERAWATAN',
      'location': 'Gubeng, Surabaya',
      'phase': 'PHASE 2 PERAWATAN',
      'currentMonth': 5,
      'totalMonths': 6,
    };
    final p = Patient.fromJson(json);
    expect(p.id, 'abc-123');
    expect(p.name, 'Siti Aminah');
    expect(p.currentMonth, 5);
    expect(p.phone, isNull);
  });

  test('Patient.fromJson parses detail-endpoint fields', () {
    final json = {
      'id': 'abc-123',
      'nik': '3578010000000001',
      'name': 'Siti Aminah',
      'status': 'DALAM PERAWATAN',
      'location': 'Gubeng, Surabaya',
      'phase': 'PHASE 2 PERAWATAN',
      'currentMonth': 5,
      'totalMonths': 6,
      'phone': '+62 811 3452 900',
      'address': 'Jl. Test No.1',
      'dob': '1989-08-17',
      'regionName': 'Gubeng',
      'photoUrl': null,
    };
    final p = Patient.fromJson(json);
    expect(p.phone, '+62 811 3452 900');
    expect(p.dob, '1989-08-17');
    expect(p.regionName, 'Gubeng');
  });
}
```

Create `mobile/test/models/adherence_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:projekakhir/data/models/adherence_model.dart';

void main() {
  test('AdherenceSummary.fromJson parses correctly', () {
    final json = {
      'percentage': 84.0,
      'target': 95,
      'dosesTaken': 25,
      'dosesTotal': 30,
      'streakDays': 3,
      'currentPhase': 'phase_2',
    };
    final s = AdherenceSummary.fromJson(json);
    expect(s.percentage, 84.0);
    expect(s.target, 95);
    expect(s.streakDays, 3);
    expect(s.currentPhase, 'phase_2');
  });

  test('AdherenceCalendar.fromJson parses days list', () {
    final json = {
      'year': 2024,
      'month': 10,
      'days': [
        {'date': '2024-10-01', 'status': 'taken'},
        {'date': '2024-10-02', 'status': 'missed'},
      ],
    };
    final c = AdherenceCalendar.fromJson(json);
    expect(c.days.length, 2);
    expect(c.days[0].status, 'taken');
    expect(c.days[1].date, '2024-10-02');
  });
}
```

- [ ] **Step 3.2: Run tests to verify they fail**

```bash
cd mobile
flutter test test/models/
```

Expected: FAIL — `Patient.fromJson`, `AdherenceSummary` not found.

- [ ] **Step 3.3: Update `lib/data/models/patient_model.dart`**

Replace the entire file:

```dart
class Patient {
  final String id;
  final String name;
  final String status;
  final String location;
  final String phase;
  final int currentMonth;
  final int totalMonths;
  // Detail fields — null when constructed from list endpoint
  final String? nik;
  final String? phone;
  final String? address;
  final String? dob;
  final String? regionName;
  final String? photoUrl;

  Patient({
    required this.id,
    required this.name,
    required this.status,
    required this.location,
    required this.phase,
    required this.currentMonth,
    required this.totalMonths,
    this.nik,
    this.phone,
    this.address,
    this.dob,
    this.regionName,
    this.photoUrl,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      location: json['location'] as String,
      phase: json['phase'] as String,
      currentMonth: json['currentMonth'] as int,
      totalMonths: json['totalMonths'] as int,
      nik: json['nik'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      dob: json['dob'] as String?,
      regionName: json['regionName'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );
  }
}
```

- [ ] **Step 3.4: Create `lib/data/models/adherence_model.dart`**

```dart
class AdherenceSummary {
  final double percentage;
  final int target;
  final int dosesTaken;
  final int dosesTotal;
  final int streakDays;
  final String currentPhase;

  const AdherenceSummary({
    required this.percentage,
    required this.target,
    required this.dosesTaken,
    required this.dosesTotal,
    required this.streakDays,
    required this.currentPhase,
  });

  factory AdherenceSummary.fromJson(Map<String, dynamic> json) {
    return AdherenceSummary(
      percentage: (json['percentage'] as num).toDouble(),
      target: json['target'] as int,
      dosesTaken: json['dosesTaken'] as int,
      dosesTotal: json['dosesTotal'] as int,
      streakDays: json['streakDays'] as int,
      currentPhase: json['currentPhase'] as String,
    );
  }

  factory AdherenceSummary.empty() => const AdherenceSummary(
        percentage: 0,
        target: 95,
        dosesTaken: 0,
        dosesTotal: 0,
        streakDays: 0,
        currentPhase: 'phase_1',
      );
}

class AdherenceDay {
  final String date;
  final String status;

  const AdherenceDay({required this.date, required this.status});

  factory AdherenceDay.fromJson(Map<String, dynamic> json) {
    return AdherenceDay(
      date: json['date'] as String,
      status: json['status'] as String,
    );
  }
}

class AdherenceCalendar {
  final int year;
  final int month;
  final List<AdherenceDay> days;

  const AdherenceCalendar({
    required this.year,
    required this.month,
    required this.days,
  });

  factory AdherenceCalendar.fromJson(Map<String, dynamic> json) {
    return AdherenceCalendar(
      year: json['year'] as int,
      month: json['month'] as int,
      days: (json['days'] as List)
          .map((d) => AdherenceDay.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }

  factory AdherenceCalendar.empty(int year, int month) =>
      AdherenceCalendar(year: year, month: month, days: []);
}
```

- [ ] **Step 3.5: Run tests to verify they pass**

```bash
flutter test test/models/
```

Expected: All 4 tests PASS.

- [ ] **Step 3.6: Commit**

```bash
cd ..
git add mobile/lib/data/models/ mobile/test/models/
git commit -m "feat(mobile): extend Patient model + add adherence models with fromJson"
```

---

## Task 4: Fix Profile model — align with backend JSON keys

**Files:**
- Modify: `mobile/lib/data/models/profile_model.dart`

The backend returns `fullName` / `specialization` / `regionName` but `Profile.fromJson` currently reads `name` / `role` / `wilayah`. Also need `regionId` for the PUT payload.

- [ ] **Step 4.1: Replace `lib/data/models/profile_model.dart`**

```dart
class Profile {
  final String name;           // maps to backend's fullName
  final String role;           // maps to backend's specialization
  final String facilityName;
  final String facilityRole;
  final String assignmentLocation;
  final String? wilayah;       // maps to backend's regionName
  final String? regionId;      // UUID — needed for PUT /profile/me
  final String email;
  final String phone;
  final String address;

  Profile({
    required this.name,
    required this.role,
    required this.facilityName,
    required this.facilityRole,
    required this.assignmentLocation,
    this.wilayah,
    this.regionId,
    required this.email,
    required this.phone,
    required this.address,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      name: json['fullName'] as String? ?? '',
      role: json['specialization'] as String? ?? '',
      facilityName: json['facilityName'] as String? ?? '',
      facilityRole: json['facilityRole'] as String? ?? '',
      assignmentLocation: json['assignmentLocation'] as String? ?? '',
      wilayah: json['regionName'] as String?,
      regionId: json['regionId']?.toString(),
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
    );
  }

  // Sends the keys that UpdateProfileDto expects on the backend
  Map<String, dynamic> toJson() {
    return {
      'fullName': name,
      'specialization': role,
      'facilityName': facilityName,
      'facilityRole': facilityRole,
      'assignmentLocation': assignmentLocation,
      if (regionId != null) 'regionId': regionId,
      'phone': phone,
      'address': address,
    };
  }
}
```

- [ ] **Step 4.2: Verify build**

```bash
cd mobile && flutter build apk --debug 2>&1 | grep -E "error:|warning:" | head -20
```

Expected: No errors. (Warnings about unused imports are fine.)

- [ ] **Step 4.3: Commit**

```bash
cd ..
git add mobile/lib/data/models/profile_model.dart
git commit -m "fix(mobile): align Profile fromJson/toJson with backend field names"
```

---

## Task 5: Create ApiPatientRepository and ApiAdherenceRepository

**Files:**
- Create: `mobile/lib/data/repositories/api_patient_repository.dart`
- Create: `mobile/lib/data/repositories/api_adherence_repository.dart`

- [ ] **Step 5.1: Create `lib/data/repositories/api_patient_repository.dart`**

```dart
import '../models/patient_model.dart';
import 'patient_repository.dart';
import '../../core/api_client.dart';

class ApiPatientRepository implements IPatientRepository {
  final ApiClient _client;

  ApiPatientRepository(this._client);

  @override
  Future<List<Patient>> getMonitoringPatients() async {
    final data = await _client.get('/patients') as List;
    return data
        .map((e) => Patient.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Patient> getById(String id) async {
    final data =
        await _client.get('/patients/$id') as Map<String, dynamic>;
    return Patient.fromJson(data);
  }

  Future<Patient> update(String id, Map<String, dynamic> body) async {
    final data =
        await _client.put('/patients/$id', body) as Map<String, dynamic>;
    return Patient.fromJson(data);
  }
}
```

- [ ] **Step 5.2: Create `lib/data/repositories/api_adherence_repository.dart`**

```dart
import '../models/adherence_model.dart';
import '../../core/api_client.dart';

class ApiAdherenceRepository {
  final ApiClient _client;

  ApiAdherenceRepository(this._client);

  Future<AdherenceSummary> getSummary(String patientId) async {
    final data = await _client
        .get('/patients/$patientId/adherence/summary') as Map<String, dynamic>;
    return AdherenceSummary.fromJson(data);
  }

  Future<AdherenceCalendar> getCalendar(
      String patientId, int year, int month) async {
    final data = await _client.get(
            '/patients/$patientId/adherence/calendar?year=$year&month=$month')
        as Map<String, dynamic>;
    return AdherenceCalendar.fromJson(data);
  }

  Future<void> log(String patientId, String logDate, String status,
      {String? notes}) async {
    await _client.post('/patients/$patientId/adherence/log', {
      'logDate': logDate,
      'status': status,
      if (notes != null) 'notes': notes,
    });
  }
}
```

- [ ] **Step 5.3: Verify build**

```bash
cd mobile && flutter build apk --debug 2>&1 | grep "error:" | head -10
```

Expected: No errors.

- [ ] **Step 5.4: Commit**

```bash
cd ..
git add mobile/lib/data/repositories/api_patient_repository.dart \
        mobile/lib/data/repositories/api_adherence_repository.dart
git commit -m "feat(mobile): add ApiPatientRepository and ApiAdherenceRepository"
```

---

## Task 6: Update ApiProfileRepository to use ApiClient

**Files:**
- Modify: `mobile/lib/data/repositories/api_profile_repository.dart`

- [ ] **Step 6.1: Replace `lib/data/repositories/api_profile_repository.dart`**

```dart
import '../models/profile_model.dart';
import 'profile_repository.dart';
import '../../core/api_client.dart';

class ApiProfileRepository implements IProfileRepository {
  final ApiClient _client;

  ApiProfileRepository(this._client);

  @override
  Future<Profile> getProfileData() async {
    final data =
        await _client.get('/profile/me') as Map<String, dynamic>;
    return Profile.fromJson(data);
  }

  @override
  Future<void> updateProfileData(Profile profile) async {
    await _client.put('/profile/me', profile.toJson());
  }
}
```

- [ ] **Step 6.2: Verify build**

```bash
cd mobile && flutter build apk --debug 2>&1 | grep "error:" | head -10
```

Expected: No errors.

- [ ] **Step 6.3: Commit**

```bash
cd ..
git add mobile/lib/data/repositories/api_profile_repository.dart
git commit -m "refactor(mobile): ApiProfileRepository uses ApiClient instead of raw http"
```

---

## Task 7: Auth guard in main.dart

**Files:**
- Modify: `mobile/lib/main.dart`

- [ ] **Step 7.1: Replace `lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'core/api_client.dart';
import 'presentation/auth/login_page.dart';
import 'presentation/monitoring/monitoring_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0052CC)),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: FutureBuilder<bool>(
        future: ApiClient.hasToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data == true
              ? const MonitoringPage()
              : const LoginPage();
        },
      ),
    );
  }
}
```

- [ ] **Step 7.2: Commit**

```bash
cd ..
git add mobile/lib/main.dart
git commit -m "feat(mobile): auth guard on startup — route to Login or Monitoring based on stored token"
```

---

## Task 8: Wire login page

**Files:**
- Modify: `mobile/lib/presentation/auth/login_page.dart`

- [ ] **Step 8.1: Read the current file**

```bash
cat mobile/lib/presentation/auth/login_page.dart
```

Note the exact class name of `_LoginPageState` and the location of `_handleLogin()`.

- [ ] **Step 8.2: Add imports at the top of `login_page.dart`**

Add these imports after the existing ones (or replace the entire import block):

```dart
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../monitoring/monitoring_page.dart';
```

- [ ] **Step 8.3: Add `_isLoading` state variable**

Inside `_LoginPageState`, add after the controller declarations:

```dart
bool _isLoading = false;
```

- [ ] **Step 8.4: Replace `_handleLogin()` with the async version**

Find the existing `_handleLogin()` method and replace it entirely:

```dart
Future<void> _handleLogin() async {
  if (_isLoading) return;
  setState(() => _isLoading = true);
  try {
    final client = ApiClient();
    final data = await client.post('/auth/login', {
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
    }) as Map<String, dynamic>;

    await ApiClient.saveTokens(
      data['accessToken'] as String,
      data['refreshToken'] as String,
    );

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MonitoringPage()),
      );
    }
  } catch (_) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email atau password salah')),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

- [ ] **Step 8.5: Disable the Sign-In button while loading**

Find the ElevatedButton (or similar) that calls `_handleLogin`. Wrap the `onPressed` so it shows a spinner while loading. Replace the button's `onPressed` and `child` as follows (keep all styling intact):

```dart
onPressed: _isLoading ? null : _handleLogin,
child: _isLoading
    ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      )
    : /* keep the existing child widget here, e.g. Row with Text + Icon */,
```

- [ ] **Step 8.6: Verify hot-reload compiles**

```bash
cd mobile && flutter build apk --debug 2>&1 | grep "error:" | head -10
```

Expected: No errors.

- [ ] **Step 8.7: Commit**

```bash
cd ..
git add mobile/lib/presentation/auth/login_page.dart
git commit -m "feat(mobile): wire login page to POST /auth/login with loading state"
```

---

## Task 9: Wire monitoring page

**Files:**
- Modify: `mobile/lib/presentation/monitoring/monitoring_page.dart`

- [ ] **Step 9.1: Update imports in `monitoring_page.dart`**

Replace the repository import line (the one that imports `MockPatientRepository`) with:

```dart
import '../../core/api_client.dart';
import '../../data/repositories/api_patient_repository.dart';
```

- [ ] **Step 9.2: Replace the repository instantiation**

Find the line:
```dart
final IPatientRepository _repository = MockPatientRepository();
```

Replace with:
```dart
final _repository = ApiPatientRepository(ApiClient());
```

- [ ] **Step 9.3: Verify build**

```bash
cd mobile && flutter build apk --debug 2>&1 | grep "error:" | head -10
```

Expected: No errors.

- [ ] **Step 9.4: Commit**

```bash
cd ..
git add mobile/lib/presentation/monitoring/monitoring_page.dart
git commit -m "feat(mobile): monitoring page loads patients from live API"
```

---

## Task 10: Wire patient detail page

**Files:**
- Modify: `mobile/lib/presentation/monitoring/patient_detail_page.dart`

This is the most involved change. The page is currently a `StatelessWidget` (or `StatefulWidget`) with all data hardcoded. It needs to become a `StatefulWidget` that loads real data concurrently.

- [ ] **Step 10.1: Read the current file in full**

```bash
cat mobile/lib/presentation/monitoring/patient_detail_page.dart
```

Identify:
- Whether it's currently Stateless or Stateful
- The `_buildHeaderInfo()` method — where it reads phone, wilayah, DOB
- The `_buildTreatmentTarget()` method — where it shows 84%, 95%
- The `_buildStatsAndAction()` method — where it shows 25/30, 2 Days, Catat Obat button
- The `_buildCalendarSection()` method and `_buildDateItem()` — how it renders day cells

- [ ] **Step 10.2: Add imports**

At the top of the file add:

```dart
import '../../core/api_client.dart';
import '../../data/models/adherence_model.dart';
import '../../data/repositories/api_patient_repository.dart';
import '../../data/repositories/api_adherence_repository.dart';
```

- [ ] **Step 10.3: Convert to StatefulWidget if not already, add data-loading state**

Ensure the outer class extends `StatefulWidget`. In the State class, add these fields and `initState`:

```dart
late Future<_DetailBundle> _future;
final _patientRepo = ApiPatientRepository(ApiClient());
final _adherenceRepo = ApiAdherenceRepository(ApiClient());

@override
void initState() {
  super.initState();
  _future = _loadAll();
}

Future<_DetailBundle> _loadAll() async {
  final now = DateTime.now();
  final results = await Future.wait([
    _patientRepo.getById(widget.patient.id),
    _adherenceRepo.getSummary(widget.patient.id),
    _adherenceRepo.getCalendar(widget.patient.id, now.year, now.month),
  ]);
  return _DetailBundle(
    patient: results[0] as Patient,
    summary: results[1] as AdherenceSummary,
    calendar: results[2] as AdherenceCalendar,
  );
}
```

Add this private class at the bottom of the file (outside the widget classes):

```dart
class _DetailBundle {
  final Patient patient;
  final AdherenceSummary summary;
  final AdherenceCalendar calendar;
  _DetailBundle({
    required this.patient,
    required this.summary,
    required this.calendar,
  });
}
```

- [ ] **Step 10.4: Wrap the body in a FutureBuilder**

In the `build()` method, wrap the existing `Scaffold` body content in:

```dart
body: FutureBuilder<_DetailBundle>(
  future: _future,
  builder: (context, snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return Center(child: Text('Gagal memuat data: ${snapshot.error}'));
    }
    final bundle = snapshot.data!;
    return _buildContent(bundle);
  },
),
```

Then move all the existing body content (the `SingleChildScrollView` / `Column` with the four sections) into a new private method:

```dart
Widget _buildContent(_DetailBundle bundle) {
  // Move all existing body content here, replacing hardcoded values
  // with bundle.patient, bundle.summary, bundle.calendar
  return SingleChildScrollView( /* ... */ );
}
```

- [ ] **Step 10.5: Replace hardcoded values in header section**

In `_buildHeaderInfo()` (or wherever phone/wilayah/DOB appear), replace hardcoded literals:

```dart
// Replace hardcoded:  '08123323712'  →  bundle.patient.phone ?? '-'
// Replace hardcoded:  'Sukolilo'     →  bundle.patient.regionName ?? '-'
// Replace hardcoded:  '17 Agustus 1989' →  bundle.patient.dob ?? '-'
```

Pass `bundle` to these helper methods, or promote them to take the data as parameters.

- [ ] **Step 10.6: Replace hardcoded adherence values**

In `_buildTreatmentTarget()`:
```dart
// Replace 84  →  bundle.summary.percentage.toInt()
// Replace 95  →  bundle.summary.target
// The circular progress value: bundle.summary.percentage / 100
```

In `_buildStatsAndAction()`:
```dart
// Replace '25/30'   →  '${bundle.summary.dosesTaken}/${bundle.summary.dosesTotal}'
// Replace '2 Days'  →  '${bundle.summary.streakDays} Days'
```

- [ ] **Step 10.7: Wire "Catat Obat Sekarang" button**

Find the empty `onPressed: () {}` on the "Catat Obat Sekarang" button and replace:

```dart
onPressed: () async {
  final today = DateTime.now();
  final logDate =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  try {
    await _adherenceRepo.log(widget.patient.id, logDate, 'taken');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Obat berhasil dicatat')),
      );
      setState(() {
        _future = _loadAll();
      });
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mencatat: $e')),
      );
    }
  }
},
```

- [ ] **Step 10.8: Replace hardcoded calendar with live data**

Replace the static `_buildCalendarSection()` with one that uses `bundle.calendar.days`. Add this helper to convert API status strings to cell styles:

```dart
({Color bg, IconData? icon, Color? iconColor}) _statusStyle(String status) {
  switch (status) {
    case 'taken':
      return (bg: const Color(0xFFEBF5FF), icon: Icons.check, iconColor: const Color(0xFF0052CC));
    case 'missed':
      return (bg: const Color(0xFFFFE4E6), icon: Icons.close, iconColor: Colors.red);
    case 'partial':
      return (bg: const Color(0xFFFFF7E6), icon: Icons.remove, iconColor: Colors.orange);
    default: // pending, upcoming, outside_month
      return (bg: Colors.transparent, icon: null, iconColor: null);
  }
}
```

In the calendar grid builder, replace the integer-based `_buildDateItem(status)` calls with `_buildDateItem(style)` using the helper above, iterating over `bundle.calendar.days`.

- [ ] **Step 10.9: Verify build**

```bash
cd mobile && flutter build apk --debug 2>&1 | grep "error:" | head -20
```

Expected: No errors.

- [ ] **Step 10.10: Commit**

```bash
cd ..
git add mobile/lib/presentation/monitoring/patient_detail_page.dart
git commit -m "feat(mobile): patient detail loads real data — adherence summary + calendar"
```

---

## Task 11: Wire edit patient page

**Files:**
- Modify: `mobile/lib/presentation/monitoring/edit_patient_page.dart`

- [ ] **Step 11.1: Read the current file**

```bash
cat mobile/lib/presentation/monitoring/edit_patient_page.dart
```

Note: where the state is initialized (`initState` or field initializers), the form controller names, and the save button handler.

- [ ] **Step 11.2: Add imports**

```dart
import '../../core/api_client.dart';
import '../../data/repositories/api_patient_repository.dart';
```

- [ ] **Step 11.3: Add `_repo`, `_isSaving`, `_regions`, `_selectedRegionId` to state**

In the `State` class:

```dart
final _repo = ApiPatientRepository(ApiClient());
bool _isSaving = false;
List<Map<String, dynamic>> _regions = [];
String? _selectedRegionId;
```

- [ ] **Step 11.4: Load regions in `initState` and pre-fill form from widget.patient**

Replace (or extend) `initState`:

```dart
@override
void initState() {
  super.initState();
  // Pre-fill controllers from the patient passed in
  _nameController.text = widget.patient.name;
  _dobController.text = widget.patient.dob ?? '';
  _phoneController.text = widget.patient.phone ?? '';
  _wilayahController.text = widget.patient.regionName ?? '';
  // Load regions for the dropdown
  _loadRegions();
}

Future<void> _loadRegions() async {
  try {
    final data = await ApiClient().get('/regions') as List;
    if (mounted) {
      setState(() {
        _regions = data.cast<Map<String, dynamic>>();
        // Pre-select region that matches the patient's regionName
        final match = _regions.firstWhere(
          (r) => r['name'] == widget.patient.regionName,
          orElse: () => {},
        );
        _selectedRegionId = match['id'] as String?;
      });
    }
  } catch (_) {}
}
```

Note: `_nameController`, `_dobController`, `_phoneController`, `_wilayahController` must match the actual controller names in the file — check Step 11.1.

- [ ] **Step 11.5: Replace the save button handler**

Find the existing `onPressed` on the save button (currently shows a SnackBar and pops). Replace:

```dart
onPressed: _isSaving
    ? null
    : () async {
        setState(() => _isSaving = true);
        try {
          await _repo.update(widget.patient.id, {
            'fullName': _nameController.text.trim(),
            'dob': _dobController.text.trim().isNotEmpty
                ? _dobController.text.trim()
                : null,
            'phone': _phoneController.text.trim(),
            if (_selectedRegionId != null) 'regionId': _selectedRegionId,
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Data pasien berhasil diperbarui')),
            );
            Navigator.pop(context, true);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal menyimpan: $e')),
            );
          }
        } finally {
          if (mounted) setState(() => _isSaving = false);
        }
      },
```

- [ ] **Step 11.6: Update wilayah dropdown to use loaded regions**

Find where `_wilayahList` (the hardcoded 31-item list) is used in the dropdown. Replace the items source:

```dart
// Before: items: _wilayahList.map(...).toList()
// After:
items: _regions
    .map((r) => DropdownMenuItem<String>(
          value: r['id'] as String,
          child: Text(r['name'] as String),
        ))
    .toList(),
value: _selectedRegionId,
onChanged: (val) => setState(() => _selectedRegionId = val),
```

Remove the now-unused `_wilayahList` field.

- [ ] **Step 11.7: Verify build**

```bash
cd mobile && flutter build apk --debug 2>&1 | grep "error:" | head -10
```

Expected: No errors.

- [ ] **Step 11.8: Commit**

```bash
cd ..
git add mobile/lib/presentation/monitoring/edit_patient_page.dart
git commit -m "feat(mobile): edit patient pre-fills from real data and saves via PUT /patients/:id"
```

---

## Task 12: Wire profile page — swap mock + wire logout

**Files:**
- Modify: `mobile/lib/presentation/profile/profile_page.dart`

- [ ] **Step 12.1: Update imports in `profile_page.dart`**

Replace the mock repository import with:

```dart
import '../../core/api_client.dart';
import '../../data/repositories/api_profile_repository.dart';
import '../auth/login_page.dart';
```

- [ ] **Step 12.2: Replace the repository instantiation**

Find:
```dart
final IProfileRepository _repository = MockProfileRepository();
```

Replace with:
```dart
final _repository = ApiProfileRepository(ApiClient());
```

- [ ] **Step 12.3: Wire the logout button**

Find the `LogoutButton` widget (or the `ElevatedButton` / `OutlinedButton` for logout) and its `onPressed: () {}`. Replace:

```dart
onPressed: () async {
  try {
    await ApiClient().post('/auth/logout');
  } catch (_) {
    // Clear tokens locally even if the API call fails
  }
  await ApiClient.clearTokens();
  if (context.mounted) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }
},
```

- [ ] **Step 12.4: Pass the real repository to EditProfilePage**

Find the `Navigator.push` that opens `EditProfilePage`. Ensure it passes `_repository` (not `MockProfileRepository`):

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => EditProfilePage(
      profile: /* the loaded profile snapshot.data */,
      repository: _repository,
    ),
  ),
);
```

- [ ] **Step 12.5: Verify build**

```bash
cd mobile && flutter build apk --debug 2>&1 | grep "error:" | head -10
```

Expected: No errors.

- [ ] **Step 12.6: Commit**

```bash
cd ..
git add mobile/lib/presentation/profile/profile_page.dart
git commit -m "feat(mobile): profile page uses live API + logout wired"
```

---

## Task 13: Wire edit profile page — regions from API

**Files:**
- Modify: `mobile/lib/presentation/profile/edit_profile_page.dart`

- [ ] **Step 13.1: Update imports**

Add:

```dart
import '../../core/api_client.dart';
```

- [ ] **Step 13.2: Replace hardcoded `_wilayahList` with API-loaded regions**

Find the hardcoded list field (currently 31 kecamatan strings). Remove it and add:

```dart
List<String> _wilayahList = [];
List<Map<String, dynamic>> _regionsData = [];
```

In `initState`, add a `_loadRegions()` call:

```dart
@override
void initState() {
  super.initState();
  // ... existing field initialisation from widget.profile ...
  _loadRegions();
}

Future<void> _loadRegions() async {
  try {
    final data = await ApiClient().get('/regions') as List;
    if (mounted) {
      setState(() {
        _regionsData = data.cast<Map<String, dynamic>>();
        _wilayahList = _regionsData.map((r) => r['name'] as String).toList();
      });
    }
  } catch (_) {}
}
```

- [ ] **Step 13.3: Pass regionId when saving**

In `_doSave()`, after calling `repository.updateProfileData(...)`, ensure the `Profile` passed has `regionId` set. Find where the updated `Profile` object is constructed and add:

```dart
final regionId = _regionsData
    .where((r) => r['name'] == _selectedWilayah)
    .map((r) => r['id'] as String)
    .firstOrNull;

final updated = Profile(
  name: _nameController.text,
  role: _roleController.text,
  facilityName: _facilityNameController.text,
  facilityRole: _facilityRoleController.text,
  assignmentLocation: _assignmentLocationController.text,
  wilayah: _selectedWilayah,
  regionId: regionId,
  email: widget.profile.email,
  phone: _phoneController.text,
  address: _addressController.text,
);
await widget.repository?.updateProfileData(updated);
```

Note: `_nameController`, `_roleController` etc. must match actual controller names in the file. Check with Step 13.1 read first.

- [ ] **Step 13.4: Verify build**

```bash
cd mobile && flutter build apk --debug 2>&1 | grep "error:" | head -10
```

Expected: No errors.

- [ ] **Step 13.5: Commit**

```bash
cd ..
git add mobile/lib/presentation/profile/edit_profile_page.dart
git commit -m "feat(mobile): edit profile loads wilayah regions from API"
```

---

## Task 14: Run all tests + push branch + open PR

- [ ] **Step 14.1: Run all tests**

```bash
cd mobile && flutter test
```

Expected: All tests pass. If any fail, fix before continuing.

- [ ] **Step 14.2: Run a final build to confirm no compile errors**

```bash
flutter build apk --debug 2>&1 | tail -5
```

Expected: `Built build/app/outputs/flutter-apk/app-debug.apk`

- [ ] **Step 14.3: Push branch**

```bash
cd ..
git push -u origin feature/mobile-api-wiring
```

- [ ] **Step 14.4: Open PR**

```bash
gh pr create \
  --title "feat(mobile): wire all screens to live backend API" \
  --body "$(cat <<'EOF'
## Summary

- New `ApiClient` wrapping `http` with token storage (SharedPreferences), bearer injection, and 401/refresh/retry
- `Patient` model extended with detail fields + `fromJson`
- New `AdherenceSummary`, `AdherenceDay`, `AdherenceCalendar` models
- `ApiPatientRepository` and `ApiAdherenceRepository` — replace all mock data
- `Profile.fromJson`/`toJson` fixed to match backend field names (`fullName`, `specialization`, `regionName`)
- Auth guard on app startup — routes to Monitoring or Login based on stored token
- All 6 screens wired: Login, Monitoring, Patient Detail, Edit Patient, Profile, Edit Profile

## Test credentials

`siti.aminah@tbhealthwatch.test` / `Demo123!`

## How to test

1. `docker compose up --build` from repo root (backend at http://localhost:5000)
2. Run Flutter app on Android emulator (`flutter run`)
3. Log in with demo credentials → should reach Monitoring with 5 real patients
4. Tap a patient → real adherence % + calendar
5. Edit patient → form pre-filled from real data, save works
6. Profile → real profile loaded, edit saves, logout clears session

Closes #5
EOF
)"
```

---

## Self-Review Notes

- `_nameController` etc. in Tasks 11 and 13 say "check actual names" — Step 11.1 and 13.1 both have read steps to verify before editing.
- `firstOrNull` in Task 13.3 requires Dart 2.14+ / Flutter 3+. Package constraint is `^3.11.0` so it's available.
- Task 10 (patient detail) is the most structurally invasive. If the page is already `StatefulWidget`, skip the conversion sub-step. If it's `StatelessWidget`, the conversion is required before adding `initState`.
- `_DetailBundle` private class must be defined at file level (outside the widget), not inside the State class.
