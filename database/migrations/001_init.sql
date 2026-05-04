-- =============================================================================
-- Migration 001: Initial schema for TB Health Watch
-- PostgreSQL 14+
-- Apply with: psql <connection_string> -f database/migrations/001_init.sql
-- =============================================================================

-- Enable pgcrypto for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =============================================================================
-- Table 1: regions
-- =============================================================================
CREATE TABLE regions (
    id         UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    name       TEXT        NOT NULL,
    code       TEXT        NOT NULL UNIQUE,   -- e.g. 'SURABAYA.ASEMROWO'
    kota       TEXT        NOT NULL DEFAULT 'Surabaya',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
-- Table 2: medications
-- =============================================================================
CREATE TABLE medications (
    id                 UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    code               TEXT        NOT NULL UNIQUE,   -- e.g. 'R', 'H', 'Z', 'E', 'S'
    name               TEXT        NOT NULL,
    default_dosage_mg  INTEGER,
    unit               TEXT        NOT NULL DEFAULT 'mg',
    category           TEXT        NOT NULL CHECK (category IN ('first_line', 'second_line')),
    notes              TEXT,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
-- Table 3: users
-- =============================================================================
CREATE TABLE users (
    id                  UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    email               TEXT        NOT NULL UNIQUE,
    password_hash       TEXT        NOT NULL,
    full_name           TEXT        NOT NULL,
    specialization      TEXT,                          -- e.g. 'Epidemiology Specialist'
    facility_name       TEXT,                          -- e.g. 'RSUD Dr. Soetomo'
    facility_role       TEXT,                          -- e.g. 'Koordinator Pemantauan Wilayah Gubeng'
    assignment_location TEXT,
    region_id           UUID        REFERENCES regions(id) ON DELETE SET NULL,
    phone               TEXT,
    address             TEXT,
    avatar_url          TEXT,
    is_verified         BOOLEAN     NOT NULL DEFAULT false,
    last_login_at       TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
-- Table 4: refresh_tokens
-- =============================================================================
CREATE TABLE refresh_tokens (
    id          UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  TEXT        NOT NULL UNIQUE,
    expires_at  TIMESTAMPTZ NOT NULL,
    revoked_at  TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
-- Table 5: patients
-- =============================================================================
CREATE TABLE patients (
    id                    UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    nik                   TEXT        NOT NULL UNIQUE,
    full_name             TEXT        NOT NULL,
    dob                   DATE        NOT NULL,
    sex                   CHAR(1)     NOT NULL CHECK (sex IN ('M', 'F')),
    phone                 TEXT,
    address               TEXT,
    region_id             UUID        REFERENCES regions(id) ON DELETE SET NULL,
    photo_url             TEXT,
    registered_by_user_id UUID        REFERENCES users(id) ON DELETE SET NULL,
    registered_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at            TIMESTAMPTZ                          -- nullable, soft-delete
);

-- =============================================================================
-- Table 6: patient_treatments
-- =============================================================================
CREATE TABLE patient_treatments (
    id                       UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    patient_id               UUID        NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    phase_1_start_date       DATE        NOT NULL,
    phase_1_end_date         DATE        NOT NULL,
    phase_2_start_date       DATE,
    phase_2_end_date         DATE,
    treatment_completed_date DATE,
    status                   TEXT        NOT NULL DEFAULT 'active'
                             CHECK (status IN ('active', 'completed', 'discontinued')),
    notes                    TEXT,
    created_by_user_id       UUID        REFERENCES users(id) ON DELETE SET NULL,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT chk_phase1 CHECK (phase_1_end_date >= phase_1_start_date),
    CONSTRAINT chk_phase2 CHECK (
        (phase_2_start_date IS NULL AND phase_2_end_date IS NULL) OR
        (
            phase_2_start_date >= phase_1_end_date AND
            (phase_2_end_date IS NULL OR phase_2_end_date >= phase_2_start_date)
        )
    ),
    CONSTRAINT chk_phase2_requires_start CHECK (
        phase_2_end_date IS NULL OR phase_2_start_date IS NOT NULL
    )
);

-- Only one active treatment per patient
CREATE UNIQUE INDEX idx_patient_treatments_one_active
    ON patient_treatments (patient_id)
    WHERE status = 'active';

-- =============================================================================
-- View: v_patient_current_status
-- =============================================================================
CREATE OR REPLACE VIEW v_patient_current_status AS
SELECT
    p.id          AS patient_id,
    p.full_name,
    pt.id         AS treatment_id,
    CASE
        WHEN pt.id IS NULL
            THEN 'Tidak Ada Pengobatan'
        WHEN pt.treatment_completed_date IS NOT NULL
             AND CURRENT_DATE >= pt.treatment_completed_date
            THEN 'Sembuh'
        WHEN CURRENT_DATE < pt.phase_1_end_date
            THEN 'Resiko Tinggi'
        WHEN CURRENT_DATE < (pt.phase_1_end_date + INTERVAL '4 months')
            THEN 'Dalam Perawatan'
        ELSE
          CASE pt.status
            WHEN 'completed'    THEN 'Selesai'
            WHEN 'discontinued' THEN 'Dihentikan'
            ELSE 'Perlu Evaluasi'
          END
    END AS status
FROM patients p
LEFT JOIN patient_treatments pt
    ON pt.patient_id = p.id AND pt.status = 'active'
WHERE p.deleted_at IS NULL;

-- =============================================================================
-- Table 7: daily_medication_targets
-- =============================================================================
CREATE TABLE daily_medication_targets (
    id                 UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    target_date        DATE        NOT NULL UNIQUE,
    notes              TEXT,
    created_by_user_id UUID        REFERENCES users(id) ON DELETE SET NULL,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
-- Table 8: daily_medication_target_items
-- =============================================================================
CREATE TABLE daily_medication_target_items (
    id            UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    target_id     UUID        NOT NULL REFERENCES daily_medication_targets(id) ON DELETE CASCADE,
    medication_id UUID        NOT NULL REFERENCES medications(id) ON DELETE RESTRICT,
    dosage_mg     INTEGER,
    sequence      SMALLINT    NOT NULL DEFAULT 1,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
    ,CONSTRAINT uq_target_medication UNIQUE (target_id, medication_id)
);

-- =============================================================================
-- Table 9: patient_medication_logs
-- =============================================================================
CREATE TABLE patient_medication_logs (
    id                    UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    patient_treatment_id  UUID        NOT NULL REFERENCES patient_treatments(id) ON DELETE CASCADE,
    log_date              DATE        NOT NULL,
    target_item_id        UUID        REFERENCES daily_medication_target_items(id) ON DELETE SET NULL,
    medication_id         UUID        NOT NULL REFERENCES medications(id) ON DELETE RESTRICT,
    dosage_mg             INTEGER,
    status                TEXT        NOT NULL DEFAULT 'pending'
                          CHECK (status IN ('pending', 'taken', 'missed', 'partial')),
    taken_at              TIMESTAMPTZ,
    recorded_by_user_id   UUID        REFERENCES users(id) ON DELETE SET NULL,
    notes                 TEXT,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT uq_patient_log_date_med UNIQUE (patient_treatment_id, log_date, medication_id)
);

-- =============================================================================
-- Table 10: notifications
-- =============================================================================
CREATE TABLE notifications (
    id                UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    recipient_user_id UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type              TEXT        NOT NULL CHECK (type IN ('treatment_due', 'patient_added', 'system')),
    title             TEXT        NOT NULL,
    body              TEXT,
    data_json         JSONB,
    is_read           BOOLEAN     NOT NULL DEFAULT false,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    read_at           TIMESTAMPTZ
);

-- =============================================================================
-- Table 11: audit_logs
-- =============================================================================
CREATE TABLE audit_logs (
    id           UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id      UUID        REFERENCES users(id) ON DELETE SET NULL,
    entity_type  TEXT        NOT NULL,
    entity_id    UUID,
    action       TEXT        NOT NULL CHECK (action IN ('create', 'update', 'delete', 'view_phi')),
    diff_json    JSONB,
    ip_address   TEXT,
    user_agent   TEXT,
    occurred_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================================================
-- Indexes
-- =============================================================================
-- Note: idx_patient_treatments_one_active (unique) was created above with the table

CREATE INDEX idx_patient_medication_logs_treatment_date
    ON patient_medication_logs (patient_treatment_id, log_date DESC);

CREATE INDEX idx_daily_medication_targets_date
    ON daily_medication_targets (target_date DESC);

CREATE INDEX idx_patients_region_active
    ON patients (region_id)
    WHERE deleted_at IS NULL;

-- Notification unread badge
CREATE INDEX idx_notifications_user_unread
    ON notifications (recipient_user_id)
    WHERE is_read = false;

-- Audit log per entity lookups
CREATE INDEX idx_audit_logs_entity
    ON audit_logs (entity_type, entity_id);

-- Refresh token per-user queries
CREATE INDEX idx_refresh_tokens_user_active
    ON refresh_tokens (user_id, expires_at)
    WHERE revoked_at IS NULL;

-- Daily compliance rate queries
CREATE INDEX idx_patient_medication_logs_date
    ON patient_medication_logs (log_date DESC);
