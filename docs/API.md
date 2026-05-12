# TB Health Watch — API Reference

Base URL (Docker): `http://localhost:5000/api`  
Base URL (Android emulator): `http://10.0.2.2:5000/api`  
Interactive docs (Scalar): `http://localhost:5000/scalar/v1`

All endpoints except `/auth/register` and `/auth/login` require:
```
Authorization: Bearer <accessToken>
```

---

## Auth

### POST `/auth/register`
Create a new user account.

**Body:**
```json
{
  "email": "user@example.com",
  "password": "Min8chars!",
  "fullName": "Dr. Full Name",
  "regionId": "uuid (optional)",
  "specialization": "optional",
  "facilityName": "optional",
  "facilityRole": "optional",
  "assignmentLocation": "optional",
  "phone": "optional",
  "address": "optional"
}
```

**Response 200:**
```json
{
  "accessToken": "eyJ...",
  "refreshToken": "base64string",
  "user": { "id": "uuid", "email": "...", "fullName": "..." }
}
```

---

### POST `/auth/login`
**Body:** `{ "email": "...", "password": "..." }`  
**Response 200:** same as register  
**Response 401:** invalid credentials

**Demo credentials:**
- `siti.aminah@tbhealthwatch.test` / `Demo123!`
- `admin@tbhealthwatch.test` / `Admin123!`

---

### POST `/auth/refresh`
**Body:** `{ "refreshToken": "..." }`  
**Response 200:** new `{ accessToken, refreshToken, user }`  
**Response 401:** token expired or already used

---

### POST `/auth/logout` *(requires auth)*
Revokes all active refresh tokens for the current user.  
**Response 204**

---

## Profile

### GET `/profile/me` *(requires auth)*
Returns the authenticated user's profile.

**Response 200:**
```json
{
  "id": "uuid",
  "email": "...",
  "fullName": "Dr. Siti Aminah",
  "specialization": "Epidemiology Specialist",
  "facilityName": "RSUD Dr. Soetomo",
  "facilityRole": "...",
  "assignmentLocation": "...",
  "regionId": "uuid",
  "regionName": "Gubeng",
  "phone": "+62 811 3452 900",
  "address": "...",
  "avatarUrl": null
}
```

---

### PUT `/profile/me` *(requires auth)*
Update own profile. `fullName` is required (max 200 chars).

**Body:** all `ProfileDto` fields except `id`, `email`, `regionName`.  
**Response 200:** updated `ProfileDto`

---

## Regions

### GET `/regions` *(requires auth)*
Returns all 31 Surabaya kecamatan.

**Response 200:**
```json
[
  { "id": "uuid", "name": "Gubeng", "code": "SURABAYA.GUBENG", "kota": "Surabaya" },
  ...
]
```

---

## Patients

### GET `/patients` *(requires auth)*
Returns all active patients with treatment status.

**Response 200:**
```json
[
  {
    "id": "uuid",
    "nik": "3578012345678901",
    "name": "Siti Aminah",
    "status": "DALAM PERAWATAN",
    "location": "Gubeng, Surabaya",
    "phase": "PHASE 2 PERAWATAN",
    "currentMonth": 5,
    "totalMonths": 6
  }
]
```

---

### GET `/patients/{id}` *(requires auth)*
Returns full patient detail.

**Response 200:** all list fields plus `phone`, `address`, `dob`, `regionName`, `photoUrl`  
**Response 404:** patient not found

---

### PUT `/patients/{id}` *(requires auth)*
Update patient info. `fullName` is required.

**Body:**
```json
{
  "fullName": "Updated Name",
  "dob": "1989-08-17",
  "regionId": "uuid",
  "phone": "+62 812 ...",
  "address": "Jl. ..."
}
```

**Response 200:** updated `PatientDetailDto`  
**Response 404:** patient not found

---

## Adherence

### GET `/patients/{id}/adherence/summary` *(requires auth)*
Returns adherence statistics for the patient's active treatment.

**Response 200:**
```json
{
  "percentage": 84.0,
  "target": 95,
  "dosesTaken": 25,
  "dosesTotal": 30,
  "streakDays": 3,
  "currentPhase": "phase_2"
}
```

---

### GET `/patients/{id}/adherence/calendar?year=YYYY&month=MM` *(requires auth)*
Returns day-by-day adherence status for the requested month.

**Response 200:**
```json
{
  "year": 2024,
  "month": 10,
  "days": [
    { "date": "2024-10-01", "status": "taken" },
    { "date": "2024-10-02", "status": "missed" },
    { "date": "2024-10-03", "status": "pending" },
    { "date": "2024-10-15", "status": "upcoming" },
    { "date": "2024-09-30", "status": "outside_month" }
  ]
}
```

**Status values:** `taken` | `missed` | `partial` | `pending` | `upcoming` | `outside_month`

---

### POST `/patients/{id}/adherence/log` *(requires auth)*
Record or update a daily dose. Idempotent — posting the same date twice updates the record.

**Body:**
```json
{
  "logDate": "2024-10-01",
  "status": "taken",
  "notes": "optional"
}
```

**Status values:** `taken` | `missed` | `partial`  
**Response 204**  
**Response 404:** no active treatment for this patient
