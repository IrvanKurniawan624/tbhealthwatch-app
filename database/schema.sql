-- =============================================================================
-- Migration 001: Initial schema for TB Health Watch
-- PostgreSQL 14+
-- Apply with: psql <connection_string> -f database/migrations/001_init.sql
-- =============================================================================

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
-- Table 2: users
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
-- Table 3: refresh_tokens
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
-- Table 4: patients
-- =============================================================================
CREATE TABLE patients (
    id                    UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    nik                   TEXT        NOT NULL UNIQUE,
    full_name             TEXT        NOT NULL,
    dob                   DATE        NOT NULL,
    gender                   CHAR(1)     NOT NULL CHECK (gender IN ('M', 'F')),
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
-- Table 5: medication_adherence
-- Stores the two-phase TB treatment plan per patient.
-- One active row per patient at a time (unique partial index below).
-- =============================================================================
CREATE TABLE medication_adherence (
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
CREATE UNIQUE INDEX idx_medication_adherence_one_active
    ON medication_adherence (patient_id)
    WHERE status = 'active';

-- =============================================================================
-- Table 6: adherence_logs
-- One row per patient per day. Records whether the patient took their
-- medication. Phase ('phase_1' / 'phase_2') is informational text stored
-- at log time so the graph can break down adherence by treatment phase.
-- =============================================================================
CREATE TABLE adherence_logs (
    id                      UUID        NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    medication_adherence_id UUID        NOT NULL REFERENCES medication_adherence(id) ON DELETE CASCADE,
    log_date                DATE        NOT NULL,
    phase                   TEXT        NOT NULL CHECK (phase IN ('phase_1', 'phase_2')),
    status                  TEXT        NOT NULL DEFAULT 'pending'
                            CHECK (status IN ('pending', 'taken', 'missed', 'partial')),
    notes                   TEXT,
    recorded_by_user_id     UUID        REFERENCES users(id) ON DELETE SET NULL,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT uq_adherence_log_date UNIQUE (medication_adherence_id, log_date)
);

-- =============================================================================
-- View: v_patient_current_status
-- =============================================================================
CREATE OR REPLACE VIEW v_patient_current_status AS
SELECT
    p.id          AS patient_id,
    p.full_name,
    ma.id         AS medication_adherence_id,
    CASE
        WHEN ma.id IS NULL
            THEN 'Tidak Ada Pengobatan'
        WHEN ma.treatment_completed_date IS NOT NULL
             AND CURRENT_DATE >= ma.treatment_completed_date
            THEN 'Sembuh'
        WHEN CURRENT_DATE < ma.phase_1_end_date
            THEN 'Resiko Tinggi'
        WHEN CURRENT_DATE < (ma.phase_1_end_date + INTERVAL '4 months')
            THEN 'Dalam Perawatan'
        ELSE
          CASE ma.status
            WHEN 'completed'    THEN 'Selesai'
            WHEN 'discontinued' THEN 'Dihentikan'
            ELSE 'Perlu Evaluasi'
          END
    END AS status
FROM patients p
LEFT JOIN medication_adherence ma
    ON ma.patient_id = p.id AND ma.status = 'active'
WHERE p.deleted_at IS NULL;

-- =============================================================================
-- View: v_adherence_summary
-- Aggregates adherence_logs per patient per phase.
-- adherence_percentage = taken / (taken + missed + partial) * 100
-- Pending rows are excluded from the denominator (not yet recorded).
-- Use this view to power the adherence % graph, broken down by phase.
-- =============================================================================
CREATE OR REPLACE VIEW v_adherence_summary AS
SELECT
    ma.patient_id,
    ma.id                                                                       AS medication_adherence_id,
    al.phase,
    COUNT(al.id)                                                                AS total_logged_days,
    COUNT(al.id) FILTER (WHERE al.status = 'taken')                            AS taken_days,
    COUNT(al.id) FILTER (WHERE al.status = 'missed')                           AS missed_days,
    COUNT(al.id) FILTER (WHERE al.status = 'partial')                          AS partial_days,
    COUNT(al.id) FILTER (WHERE al.status = 'pending')                          AS pending_days,
    ROUND(
        COUNT(al.id) FILTER (WHERE al.status = 'taken')::NUMERIC /
        NULLIF(COUNT(al.id) FILTER (WHERE al.status != 'pending'), 0) * 100,
        2
    )                                                                           AS adherence_percentage
FROM medication_adherence ma
JOIN adherence_logs al ON al.medication_adherence_id = ma.id
GROUP BY ma.patient_id, ma.id, al.phase;

-- =============================================================================
-- Table 7: notifications
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
-- Table 8: audit_logs
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
CREATE INDEX idx_adherence_logs_adherence_date
    ON adherence_logs (medication_adherence_id, log_date DESC);

CREATE INDEX idx_adherence_logs_date
    ON adherence_logs (log_date DESC);

CREATE INDEX idx_patients_region_active
    ON patients (region_id)
    WHERE deleted_at IS NULL;

CREATE INDEX idx_notifications_user_unread
    ON notifications (recipient_user_id)
    WHERE is_read = false;

CREATE INDEX idx_audit_logs_entity
    ON audit_logs (entity_type, entity_id);

CREATE INDEX idx_refresh_tokens_user_active
    ON refresh_tokens (user_id, expires_at)
    WHERE revoked_at IS NULL;
