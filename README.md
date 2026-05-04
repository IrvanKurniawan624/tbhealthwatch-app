# TB Health Watch

A tuberculosis (TBC) patient monitoring application for medical staff and administrators in Kota Surabaya. Doctors and admins can track patients across all 31 kecamatan, record daily medication targets, and monitor treatment progress through a two-phase treatment model.

> **Scope:** Admin / doctor use only — no patient-facing portal.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter 3.x (Dart) |
| Backend | .NET 10 Web API — Clean Architecture |
| Database | PostgreSQL 14+ |
| ORM | Entity Framework Core 9 + Npgsql |

---

## Repository Structure

```
tbhealthwatch-app/
├── mobile/          # Flutter app
├── backend/         # .NET 10 Web API
├── database/        # PostgreSQL schema, migrations, seed data
└── docs/            # ERD and design docs
```

---

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Flutter SDK | ≥ 3.19 | `flutter doctor` to verify |
| Dart SDK | ≥ 3.3 | Bundled with Flutter |
| .NET SDK | 10.0 | `dotnet --version` to verify |
| PostgreSQL | ≥ 14 | Local install or Docker |
| Docker (optional) | any | For running Postgres in a container |

---

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/IrvanKurniawan624/tbhealthwatch-app.git
cd tbhealthwatch-app
```

### 2. Set up the database

**Option A — Docker (recommended for local dev)**

```bash
docker run -d \
  --name tbhw-pg \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=dev \
  -e POSTGRES_DB=tbhealthwatch \
  -p 5432:5432 \
  postgres:16
```

**Option B — Existing PostgreSQL instance**

Create a database manually:
```sql
CREATE DATABASE tbhealthwatch;
```

**Apply schema and seed data**

```bash
psql "postgresql://postgres:dev@localhost:5432/tbhealthwatch" \
  -f database/migrations/001_init.sql

psql "postgresql://postgres:dev@localhost:5432/tbhealthwatch" \
  -f database/seed.sql
```

Verify:
```sql
-- Should return 31
SELECT count(*) FROM regions;

-- Should return 5
SELECT count(*) FROM medications;

-- Demo admin
SELECT full_name, email FROM users;
```

---

### 3. Run the backend

```bash
cd backend

# Restore dependencies
dotnet restore

# Update connection string (development only)
# Edit backend/src/TBHealthWatch.Api/appsettings.Development.json:
# "DefaultConnection": "Host=localhost;Port=5432;Database=tbhealthwatch;Username=postgres;Password=dev"

# Build
dotnet build

# Run
dotnet run --project src/TBHealthWatch.Api
```

The API will be available at `http://localhost:5000`.

**Verify the profile endpoint:**
```bash
curl http://localhost:5000/api/profile/me
```

Expected response:
```json
{
  "name": "Dr. Siti Aminah",
  "role": "Epidemiology Specialist",
  "facilityName": "Fasilitas Kesehatan",
  "facilityRole": "Koordinator Pemantauan Wilayah Gubeng, Surabaya Timur",
  "assignmentLocation": "RSUD Dr. Soetomo,\nSurabaya",
  "wilayah": "Gubeng",
  "email": "siti.aminah@gmail.com",
  "phone": "+62 811 3452 900",
  "address": "Jl. Arief Rahman Hakim\nNo.99, Sukolilo, Surabaya"
}
```

---

### 4. Run the Flutter mobile app

```bash
cd mobile

# Install dependencies
flutter pub get

# Run on a connected device or emulator
flutter run
```

**Connecting to the backend from an Android emulator:**

The emulator's localhost maps to `10.0.2.2` on the host machine. The app is pre-configured to use `http://10.0.2.2:5000/api` in `ApiProfileRepository`.

To switch between mock data and the live backend, edit `mobile/lib/presentation/pages/profile_page.dart`:

```dart
// Mock (default — works without a running backend)
final IProfileRepository _repository = MockProfileRepository();

// Live backend
final IProfileRepository _repository = ApiProfileRepository(baseUrl: 'http://10.0.2.2:5000/api');
```

---

## Running Tests

**Backend**

```bash
cd backend
dotnet test
```

**Flutter**

```bash
cd mobile
flutter test
```

---

## Database Schema Overview

11 tables + 1 computed view across 4 domains:

| Domain | Tables |
|--------|--------|
| Lookup | `regions`, `medications` |
| Users | `users`, `refresh_tokens` |
| Patients | `patients`, `patient_treatments` |
| Monitoring | `daily_medication_targets`, `daily_medication_target_items`, `patient_medication_logs` |
| System | `notifications`, `audit_logs` |
| View | `v_patient_current_status` (computed treatment status) |

See `docs/erd.md` for the full entity-relationship diagram.

**Treatment status** is computed from actual calendar dates — never stored:

| Condition | Status |
|-----------|--------|
| In Phase 1 (months 0–2) | Resiko Tinggi |
| In Phase 2 months 1–4 | Dalam Perawatan |
| In Phase 2 months 5–6 | Stable |
| Treatment completed | Sembuh |

---

## Backend API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/profile/me` | Get current user profile |
| `PUT` | `/api/profile/me` | Update current user profile |

> Authentication is deferred. The demo user (`siti.aminah@gmail.com`, UUID `00000000-0000-0000-0000-000000000001`) is hardcoded in `ProfileController` until JWT auth is wired.

---

## Project Status

| Feature | Status |
|---------|--------|
| PostgreSQL schema + seed | Done |
| .NET 10 backend scaffold | Done |
| Profile GET/PUT endpoint | Done |
| Flutter profile + edit screens | Done |
| Authentication (JWT) | Deferred |
| Patient management CRUD | Deferred |
| Monitoring / medication logs | Deferred |

---

## Demo Credentials

| Field | Value |
|-------|-------|
| Email | siti.aminah@gmail.com |
| Wilayah | Gubeng |
| Facility | RSUD Dr. Soetomo, Surabaya |
