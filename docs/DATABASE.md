# Database Reference — TB Health Watch

> PostgreSQL 14+ · 8 tables · 2 computed views · UUIDv4 primary keys · snake_case

---

## App Flow Overview

```
Admin / Doctor (Flutter app)
        │
        ▼
  [Login] ──► users + refresh_tokens (auth, deferred)
        │
        ├──► [Profile Page]
        │         └── reads/writes: users
        │
        ├──► [Patient List / Add Patient]
        │         └── reads/writes: patients, regions
        │         └── reads (status): v_patient_current_status
        │
        ├──► [Patient Detail / Treatment Dates]
        │         └── reads/writes: medication_adherence
        │         └── reads: v_patient_current_status (live status)
        │
        └──► [Monitoring — Daily Adherence]
                  └── admin logs: adherence_logs (one row per patient per day)
                  └── graph reads: v_adherence_summary (% per phase)
```

Every write that touches patient data is also recorded in `audit_logs`.  
Notifications land in `notifications` when key events fire (e.g. treatment due, new patient).

---

## Table-by-Table Reference

---

### 1. `regions`
Lookup table — seeded with all 31 kecamatan of Kota Surabaya.  
Admin profiles and patients are each linked to one kecamatan.

| Column | Type | Meaning |
|--------|------|---------|
| `id` | UUID PK | Unique identifier for the kecamatan |
| `name` | TEXT | Display name, e.g. `"Gubeng"` |
| `code` | TEXT UNIQUE | Machine-readable code, e.g. `"SURABAYA.GUBENG"` |
| `kota` | TEXT | Always `"Surabaya"` for this app |
| `created_at` | TIMESTAMPTZ | When the row was inserted |
| `updated_at` | TIMESTAMPTZ | Last update time |

---

### 2. `users`
The only account type in the app — admins and doctors share this table.  
Maps 1:1 to the Flutter `Profile` model.

| Column | Type | Meaning |
|--------|------|---------|
| `id` | UUID PK | Unique account ID |
| `email` | TEXT UNIQUE | Login email |
| `password_hash` | TEXT | Bcrypt hash |
| `full_name` | TEXT | Display name |
| `specialization` | TEXT | Role/title, e.g. `"Epidemiology Specialist"` |
| `facility_name` | TEXT | Hospital / Puskesmas name |
| `facility_role` | TEXT | Role within the facility |
| `assignment_location` | TEXT | Work site address |
| `region_id` | UUID FK → regions | Kecamatan this user covers |
| `phone` | TEXT | Contact phone number |
| `address` | TEXT | Home/office address |
| `avatar_url` | TEXT | Profile photo URL |
| `is_verified` | BOOLEAN | Verified by super-admin |
| `last_login_at` | TIMESTAMPTZ | Most recent login |
| `created_at` / `updated_at` | TIMESTAMPTZ | Audit timestamps |

---

### 3. `refresh_tokens`
Stores JWT refresh tokens. Auth is deferred — table is ready but not yet wired.

| Column | Type | Meaning |
|--------|------|---------|
| `id` | UUID PK | Token record ID |
| `user_id` | UUID FK → users | Owner (cascades on user delete) |
| `token_hash` | TEXT UNIQUE | SHA-256 hash of the actual token |
| `expires_at` | TIMESTAMPTZ | Token expiry |
| `revoked_at` | TIMESTAMPTZ | Set on explicit revocation |
| `created_at` | TIMESTAMPTZ | When issued |

> **Active token** = `revoked_at IS NULL AND expires_at > now()`

---

### 4. `patients`
Core patient record.

| Column | Type | Meaning |
|--------|------|---------|
| `id` | UUID PK | Unique patient ID |
| `nik` | TEXT UNIQUE | Indonesian National ID — encrypt at application layer |
| `full_name` | TEXT | Patient's full name |
| `dob` | DATE | Date of birth |
| `gender` | CHAR(1) | `M` = Male · `F` = Female |
| `phone` | TEXT | Contact number |
| `address` | TEXT | Home address |
| `region_id` | UUID FK → regions | Patient's kecamatan |
| `photo_url` | TEXT | Patient photo URL |
| `registered_by_user_id` | UUID FK → users | Admin who registered the patient |
| `registered_at` | TIMESTAMPTZ | Registration timestamp |
| `created_at` / `updated_at` | TIMESTAMPTZ | Audit timestamps |
| `deleted_at` | TIMESTAMPTZ | **Soft-delete** — `NULL` = active |

---

### 5. `medication_adherence`
Two-phase TB treatment plan per patient. One active row per patient at a time (enforced by unique partial index).

| Column | Type | Meaning |
|--------|------|---------|
| `id` | UUID PK | Treatment record ID |
| `patient_id` | UUID FK → patients | Which patient |
| `phase_1_start_date` | DATE | Phase 1 start (Intensive, ~2 months) |
| `phase_1_end_date` | DATE | Phase 1 planned end. Must be ≥ start |
| `phase_2_start_date` | DATE | Phase 2 start (Continuation, up to 6 months) |
| `phase_2_end_date` | DATE | Phase 2 planned end |
| `treatment_completed_date` | DATE | Actual completion date |
| `status` | TEXT | `active` · `completed` · `discontinued` |
| `notes` | TEXT | Clinical notes |
| `created_by_user_id` | UUID FK → users | Admin who created the record |
| `created_at` / `updated_at` | TIMESTAMPTZ | Audit timestamps |

**Constraints:** only one `active` row per patient · phase dates must be chronologically consistent.

---

### View: `v_patient_current_status`
Status derived from today's date vs. treatment dates — never stored directly.

| Output Column | Meaning |
|---------------|---------|
| `patient_id` | Patient UUID |
| `full_name` | Patient name |
| `medication_adherence_id` | Active treatment UUID (NULL if none) |
| `status` | Computed label (see table below) |

| Condition | Status label |
|-----------|-------------|
| No active treatment row | `Tidak Ada Pengobatan` |
| `CURRENT_DATE < phase_1_end_date` | `Resiko Tinggi` |
| `CURRENT_DATE < phase_1_end_date + 4 months` | `Dalam Perawatan` |
| `treatment_completed_date` set and reached | `Sembuh` |
| Status = `completed` | `Selesai` |
| Status = `discontinued` | `Dihentikan` |
| Otherwise | `Perlu Evaluasi` |

---

### 6. `adherence_logs`
One row per patient per day. Records whether the patient took their medication. The `phase` column is informational text (`'phase_1'` or `'phase_2'`) written at log time so the graph can break down adherence by phase without recalculating.

| Column | Type | Meaning |
|--------|------|---------|
| `id` | UUID PK | Log entry ID |
| `medication_adherence_id` | UUID FK → medication_adherence | Linked treatment record (cascades) |
| `log_date` | DATE | The day being recorded |
| `phase` | TEXT | `phase_1` or `phase_2` — informational label |
| `status` | TEXT | `pending` · `taken` · `missed` · `partial` |
| `notes` | TEXT | Optional note (e.g. reason for missed dose) |
| `recorded_by_user_id` | UUID FK → users | Admin who ticked this entry |
| `created_at` / `updated_at` | TIMESTAMPTZ | Audit timestamps |

> **Unique constraint:** one log per `(medication_adherence_id, log_date)`.

---

### View: `v_adherence_summary`
Aggregates `adherence_logs` for the adherence % graph. Grouped by patient and phase.

| Output Column | Meaning |
|---------------|---------|
| `patient_id` | Patient UUID |
| `medication_adherence_id` | Treatment record UUID |
| `phase` | `phase_1` or `phase_2` |
| `total_logged_days` | All log rows for this patient + phase |
| `taken_days` | Rows with `status = 'taken'` |
| `missed_days` | Rows with `status = 'missed'` |
| `partial_days` | Rows with `status = 'partial'` |
| `pending_days` | Rows with `status = 'pending'` (not yet recorded) |
| `adherence_percentage` | `taken / (taken + missed + partial) * 100` — pending excluded |

---

### 7. `notifications`
In-app notification inbox per user.

| Column | Type | Meaning |
|--------|------|---------|
| `id` | UUID PK | Notification ID |
| `recipient_user_id` | UUID FK → users | Which admin/doctor receives this |
| `type` | TEXT | `treatment_due` · `patient_added` · `system` |
| `title` | TEXT | Short headline |
| `body` | TEXT | Full notification text |
| `data_json` | JSONB | Arbitrary payload for deep-linking |
| `is_read` | BOOLEAN | `false` = unread |
| `created_at` | TIMESTAMPTZ | When created |
| `read_at` | TIMESTAMPTZ | When opened |

---

### 8. `audit_logs`
Immutable log of every write on sensitive data.

| Column | Type | Meaning |
|--------|------|---------|
| `id` | UUID PK | Log entry ID |
| `user_id` | UUID FK → users | Who performed the action |
| `entity_type` | TEXT | Which table, e.g. `"patients"` |
| `entity_id` | UUID | Affected row |
| `action` | TEXT | `create` · `update` · `delete` · `view_phi` |
| `diff_json` | JSONB | Before/after snapshot |
| `ip_address` | TEXT | Client IP |
| `user_agent` | TEXT | Client app identifier |
| `occurred_at` | TIMESTAMPTZ | Exact action time |

---

## Foreign Key Map

```
regions ◄────────────── users (region_id)
regions ◄────────────── patients (region_id)

users ◄─────────────── refresh_tokens (user_id)
users ◄─────────────── patients (registered_by_user_id)
users ◄─────────────── medication_adherence (created_by_user_id)
users ◄─────────────── adherence_logs (recorded_by_user_id)
users ◄─────────────── notifications (recipient_user_id)
users ◄─────────────── audit_logs (user_id)

patients ◄──────────── medication_adherence (patient_id)

medication_adherence ◄── adherence_logs (medication_adherence_id)
```
