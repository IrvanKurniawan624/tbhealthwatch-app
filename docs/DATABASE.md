# Database Reference — TB Health Watch

> PostgreSQL 14+ · 11 tables · 1 computed view · UUIDv4 primary keys · snake_case

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
        ├──► [Patient Detail / Edit Treatment Dates]
        │         └── reads/writes: patient_treatments
        │         └── reads: v_patient_current_status (live status)
        │
        ├──► [Monitoring — Daily Medication Target]
        │         └── admin creates: daily_medication_targets
        │         └── admin adds meds: daily_medication_target_items
        │         └── backend fans out: patient_medication_logs (one row per patient × med)
        │
        └──► [Monitoring — Tick Compliance]
                  └── admin updates: patient_medication_logs.status
                                      (pending → taken / missed / partial)
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
| `code` | TEXT UNIQUE | Machine-readable code, e.g. `"SURABAYA.GUBENG"` — used in API filters |
| `kota` | TEXT | Always `"Surabaya"` for this app — future-proofs for multi-city expansion |
| `created_at` | TIMESTAMPTZ | When the row was inserted (set by seed) |
| `updated_at` | TIMESTAMPTZ | Last update time |

---

### 2. `medications`
Lookup table — seeded with 5 standard first-line TB drugs (R, H, Z, E, S).

| Column | Type | Meaning |
|--------|------|---------|
| `id` | UUID PK | Unique identifier |
| `code` | TEXT UNIQUE | Single-letter WHO code: `R` Rifampicin, `H` Isoniazid, `Z` Pyrazinamide, `E` Ethambutol, `S` Streptomycin |
| `name` | TEXT | Full drug name |
| `default_dosage_mg` | INTEGER | Standard dosage in milligrams (can be overridden per target) |
| `unit` | TEXT | Unit of measure — always `"mg"` for now |
| `category` | TEXT | `first_line` = standard TB protocol · `second_line` = drug-resistant TB drugs |
| `notes` | TEXT | Optional clinical notes |
| `created_at` / `updated_at` | TIMESTAMPTZ | Audit timestamps |

---

### 3. `users`
The only account type in the app — admins and doctors share this table.  
Maps 1:1 to the Flutter `Profile` model.

| Column | Type | Meaning |
|--------|------|---------|
| `id` | UUID PK | Unique account ID. Demo admin hardcoded: `00000000-0000-0000-0000-000000000001` |
| `email` | TEXT UNIQUE | Login email |
| `password_hash` | TEXT | Bcrypt hash — never stored in plain text |
| `full_name` | TEXT | Display name shown in Profile page |
| `specialization` | TEXT | Role/title, e.g. `"Epidemiology Specialist"` — shown as "PERAN" in app |
| `facility_name` | TEXT | Hospital / Puskesmas name, e.g. `"RSUD Dr. Soetomo"` |
| `facility_role` | TEXT | Role within the facility, e.g. `"Koordinator Pemantauan Wilayah Gubeng"` |
| `assignment_location` | TEXT | Free-text address of the work site |
| `region_id` | UUID FK → regions | The kecamatan this user covers / is assigned to |
| `phone` | TEXT | Contact phone number |
| `address` | TEXT | Home/office address |
| `avatar_url` | TEXT | URL to profile photo (future) |
| `is_verified` | BOOLEAN | Whether the account has been verified by a super-admin |
| `last_login_at` | TIMESTAMPTZ | Timestamp of the most recent login |
| `created_at` / `updated_at` | TIMESTAMPTZ | Audit timestamps |

---

### 4. `refresh_tokens`
Stores JWT refresh tokens so users stay logged in across sessions.  
Auth is deferred — this table is ready but not yet used by the API.

| Column | Type | Meaning |
|--------|------|---------|
| `id` | UUID PK | Token record ID |
| `user_id` | UUID FK → users | Which user this token belongs to (cascades on user delete) |
| `token_hash` | TEXT UNIQUE | SHA-256 hash of the actual token — the raw token is never stored |
| `expires_at` | TIMESTAMPTZ | When this refresh token becomes invalid |
| `revoked_at` | TIMESTAMPTZ | If set, token was explicitly revoked (logout / password change) |
| `created_at` | TIMESTAMPTZ | When the token was issued |

> **Active token** = `revoked_at IS NULL AND expires_at > now()`

---

### 5. `patients`
Core patient record. Admins register and manage patients here.

| Column | Type | Meaning |
|--------|------|---------|
| `id` | UUID PK | Unique patient ID |
| `nik` | TEXT UNIQUE | Indonesian National ID number — must be encrypted at the application layer before storage |
| `full_name` | TEXT | Patient's full legal name |
| `dob` | DATE | Date of birth — used to display age |
| `sex` | CHAR(1) | `M` = Male · `F` = Female |
| `phone` | TEXT | Patient or guardian contact number |
| `address` | TEXT | Patient's home address |
| `region_id` | UUID FK → regions | Which kecamatan the patient lives in |
| `photo_url` | TEXT | URL to patient photo (required per app spec) |
| `registered_by_user_id` | UUID FK → users | Which admin/doctor registered this patient |
| `registered_at` | TIMESTAMPTZ | When the registration happened (can differ from `created_at`) |
| `created_at` / `updated_at` | TIMESTAMPTZ | Audit timestamps |
| `deleted_at` | TIMESTAMPTZ | **Soft-delete** — patient is hidden from lists but data is preserved. `NULL` = active |

---

### 6. `patient_treatments`
Two-phase TB treatment record. One active row per patient at a time (enforced by unique partial index).

| Column | Type | Meaning |
|--------|------|---------|
| `id` | UUID PK | Treatment record ID |
| `patient_id` | UUID FK → patients | Which patient this treatment belongs to |
| `phase_1_start_date` | DATE | Day treatment begins — Phase 1 (Intensive, ~2 months). Admin picks this in the calendar picker |
| `phase_1_end_date` | DATE | Planned end of Phase 1. Must be ≥ `phase_1_start_date` |
| `phase_2_start_date` | DATE | Planned start of Phase 2 (Continuation, up to 6 months). Usually = `phase_1_end_date` |
| `phase_2_end_date` | DATE | Planned end of Phase 2. Must be ≥ `phase_2_start_date` |
| `treatment_completed_date` | DATE | Actual date admin marked treatment finished (may differ from planned end) |
| `status` | TEXT | `active` = currently in treatment · `completed` = finished normally · `discontinued` = stopped early |
| `notes` | TEXT | Clinical notes from the admin |
| `created_by_user_id` | UUID FK → users | Admin who created this treatment record |
| `created_at` / `updated_at` | TIMESTAMPTZ | Audit timestamps |

**Constraint summary:**
- Only one `active` row per patient (unique partial index)
- `phase_1_end_date >= phase_1_start_date`
- `phase_2_start_date >= phase_1_end_date` (if Phase 2 is set)
- `phase_2_end_date >= phase_2_start_date` (if end is set)

---

### View: `v_patient_current_status`
A computed view — status is never stored, it is always derived from today's date vs. the treatment dates.

| Output Column | Meaning |
|---------------|---------|
| `patient_id` | Patient UUID |
| `full_name` | Patient name |
| `treatment_id` | Active treatment UUID (NULL if no treatment) |
| `status` | Computed label (see table below) |

**Status logic:**

| Condition | Status label |
|-----------|-------------|
| No active treatment row | `Tidak Ada Pengobatan` |
| `CURRENT_DATE < phase_1_end_date` | `Resiko Tinggi` (Phase 1 — Intensive) |
| `CURRENT_DATE < phase_1_end_date + 4 months` | `Dalam Perawatan` (Phase 2 months 1–4) |
| `treatment_completed_date` set and reached | `Sembuh` (Recovered) |
| Status = `completed` | `Selesai` |
| Status = `discontinued` | `Dihentikan` |
| Otherwise | `Perlu Evaluasi` |

---

### 7. `daily_medication_targets`
Admin creates one entry per day to define "today's medication plan".  
All active patients inherit this plan (fanned out via `patient_medication_logs`).

| Column | Type | Meaning |
|--------|------|---------|
| `id` | UUID PK | Target record ID |
| `target_date` | DATE UNIQUE | The calendar day this target applies to — one per day only |
| `notes` | TEXT | Optional instruction notes for the day's regimen |
| `created_by_user_id` | UUID FK → users | Admin who created the target |
| `created_at` / `updated_at` | TIMESTAMPTZ | Audit timestamps |

---

### 8. `daily_medication_target_items`
The individual drugs and doses inside a daily target.  
E.g., Day's target might be: Rifampicin 450mg + Isoniazid 300mg.

| Column | Type | Meaning |
|--------|------|---------|
| `id` | UUID PK | Item record ID |
| `target_id` | UUID FK → daily_medication_targets | Which daily target this item belongs to (cascades on delete) |
| `medication_id` | UUID FK → medications | Which drug |
| `dosage_mg` | INTEGER | Dose for this item — overrides `medications.default_dosage_mg` if set |
| `sequence` | SMALLINT | Display order of items within the target |
| `created_at` | TIMESTAMPTZ | Insert timestamp |

---

### 9. `patient_medication_logs`
Per-patient compliance record. When a daily target is saved, the backend generates one row here for every active patient × every target item. Admin then ticks each row as taken / missed / partial.

| Column | Type | Meaning |
|--------|------|---------|
| `id` | UUID PK | Log entry ID |
| `patient_treatment_id` | UUID FK → patient_treatments | Links the log to the patient's active treatment |
| `log_date` | DATE | The day this dose was due |
| `target_item_id` | UUID FK → daily_medication_target_items | Source target item (nullable — manual logs have no target) |
| `medication_id` | UUID FK → medications | Which drug |
| `dosage_mg` | INTEGER | Dose prescribed for this patient on this day |
| `status` | TEXT | `pending` = not yet recorded · `taken` = patient took the dose · `missed` = dose was not taken · `partial` = partial compliance |
| `taken_at` | TIMESTAMPTZ | Exact timestamp when dose was marked taken |
| `recorded_by_user_id` | UUID FK → users | Admin who ticked this log entry |
| `notes` | TEXT | Optional note (e.g. reason for missed dose) |
| `created_at` / `updated_at` | TIMESTAMPTZ | Audit timestamps |

> **Unique constraint:** one log per `(patient_treatment_id, log_date, medication_id)` — prevents double-recording.

---

### 10. `notifications`
In-app notification inbox per user.

| Column | Type | Meaning |
|--------|------|---------|
| `id` | UUID PK | Notification ID |
| `recipient_user_id` | UUID FK → users | Which admin/doctor receives this notification |
| `type` | TEXT | `treatment_due` = a patient's phase is about to end · `patient_added` = new patient registered · `system` = system alert |
| `title` | TEXT | Short headline shown in the notification badge |
| `body` | TEXT | Full notification text |
| `data_json` | JSONB | Arbitrary payload (e.g. patient ID to deep-link into) |
| `is_read` | BOOLEAN | `false` = unread (shown in badge count) · `true` = already opened |
| `created_at` | TIMESTAMPTZ | When the notification was created |
| `read_at` | TIMESTAMPTZ | When the user opened it |

---

### 11. `audit_logs`
Immutable log of every write action on sensitive data. Required for medical data accountability.

| Column | Type | Meaning |
|--------|------|---------|
| `id` | UUID PK | Log entry ID |
| `user_id` | UUID FK → users | Who performed the action (NULL if system-generated) |
| `entity_type` | TEXT | Which table was affected, e.g. `"patients"`, `"patient_treatments"` |
| `entity_id` | UUID | The specific row that was changed |
| `action` | TEXT | `create` · `update` · `delete` · `view_phi` (viewing protected health information) |
| `diff_json` | JSONB | Before/after snapshot of changed fields |
| `ip_address` | TEXT | Client IP address |
| `user_agent` | TEXT | Client browser/app identifier |
| `occurred_at` | TIMESTAMPTZ | Exact time the action happened |

---

## Foreign Key Map

```
regions ◄────────────── users (region_id)
regions ◄────────────── patients (region_id)

users ◄─────────────── refresh_tokens (user_id)
users ◄─────────────── patients (registered_by_user_id)
users ◄─────────────── patient_treatments (created_by_user_id)
users ◄─────────────── daily_medication_targets (created_by_user_id)
users ◄─────────────── patient_medication_logs (recorded_by_user_id)
users ◄─────────────── notifications (recipient_user_id)
users ◄─────────────── audit_logs (user_id)

patients ◄──────────── patient_treatments (patient_id)

patient_treatments ◄── patient_medication_logs (patient_treatment_id)

medications ◄────────── daily_medication_target_items (medication_id)
medications ◄────────── patient_medication_logs (medication_id)

daily_medication_targets ◄── daily_medication_target_items (target_id)
daily_medication_target_items ◄── patient_medication_logs (target_item_id)
```
