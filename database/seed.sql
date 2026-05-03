-- =============================================================================
-- Seed data for TB Health Watch
-- PostgreSQL 14+
-- Apply AFTER migration: psql <connection_string> -f database/seed.sql
-- =============================================================================

-- =============================================================================
-- Regions: all 31 kecamatan of Kota Surabaya
-- =============================================================================
INSERT INTO regions (name, code, kota) VALUES
    ('Asemrowo',         'SURABAYA.ASEMROWO',         'Surabaya'),
    ('Benowo',           'SURABAYA.BENOWO',            'Surabaya'),
    ('Bubutan',          'SURABAYA.BUBUTAN',           'Surabaya'),
    ('Bulak',            'SURABAYA.BULAK',             'Surabaya'),
    ('Dukuh Pakis',      'SURABAYA.DUKUH_PAKIS',       'Surabaya'),
    ('Gayungan',         'SURABAYA.GAYUNGAN',          'Surabaya'),
    ('Genteng',          'SURABAYA.GENTENG',           'Surabaya'),
    ('Gubeng',           'SURABAYA.GUBENG',            'Surabaya'),
    ('Gunung Anyar',     'SURABAYA.GUNUNG_ANYAR',      'Surabaya'),
    ('Jambangan',        'SURABAYA.JAMBANGAN',         'Surabaya'),
    ('Karang Pilang',    'SURABAYA.KARANG_PILANG',     'Surabaya'),
    ('Kenjeran',         'SURABAYA.KENJERAN',          'Surabaya'),
    ('Krembangan',       'SURABAYA.KREMBANGAN',        'Surabaya'),
    ('Lakarsantri',      'SURABAYA.LAKARSANTRI',       'Surabaya'),
    ('Mulyorejo',        'SURABAYA.MULYOREJO',         'Surabaya'),
    ('Pabean Cantian',   'SURABAYA.PABEAN_CANTIAN',    'Surabaya'),
    ('Pakal',            'SURABAYA.PAKAL',             'Surabaya'),
    ('Rungkut',          'SURABAYA.RUNGKUT',           'Surabaya'),
    ('Sambikerep',       'SURABAYA.SAMBIKEREP',        'Surabaya'),
    ('Sawahan',          'SURABAYA.SAWAHAN',           'Surabaya'),
    ('Semampir',         'SURABAYA.SEMAMPIR',          'Surabaya'),
    ('Simokerto',        'SURABAYA.SIMOKERTO',         'Surabaya'),
    ('Sukolilo',         'SURABAYA.SUKOLILO',          'Surabaya'),
    ('Sukomanunggal',    'SURABAYA.SUKOMANUNGGAL',     'Surabaya'),
    ('Tambaksari',       'SURABAYA.TAMBAKSARI',        'Surabaya'),
    ('Tandes',           'SURABAYA.TANDES',            'Surabaya'),
    ('Tegalsari',        'SURABAYA.TEGALSARI',         'Surabaya'),
    ('Tenggilis Mejoyo', 'SURABAYA.TENGGILIS_MEJOYO',  'Surabaya'),
    ('Wiyung',           'SURABAYA.WIYUNG',            'Surabaya'),
    ('Wonocolo',         'SURABAYA.WONOCOLO',          'Surabaya'),
    ('Wonokromo',        'SURABAYA.WONOKROMO',         'Surabaya')
ON CONFLICT (code) DO NOTHING;

-- =============================================================================
-- Medications: 5 first-line TB drugs
-- =============================================================================
INSERT INTO medications (code, name, default_dosage_mg, unit, category) VALUES
    ('R', 'Rifampicin',    600,  'mg', 'first_line'),
    ('H', 'Isoniazid',     300,  'mg', 'first_line'),
    ('Z', 'Pyrazinamide',  1500, 'mg', 'first_line'),
    ('E', 'Ethambutol',    1200, 'mg', 'first_line'),
    ('S', 'Streptomycin',  750,  'mg', 'first_line')
ON CONFLICT (code) DO NOTHING;

-- =============================================================================
-- Demo admin user (matches Flutter MockProfileRepository)
-- =============================================================================
INSERT INTO users (
    email,
    password_hash,
    full_name,
    specialization,
    facility_name,
    facility_role,
    assignment_location,
    region_id,
    phone,
    address,
    is_verified
) VALUES (
    'siti.aminah@gmail.com',
    '$2a$12$placeholder_hash_for_dev_only',
    'Dr. Siti Aminah',
    'Epidemiology Specialist',
    'RSUD Dr. Soetomo',
    'Koordinator Pemantauan Wilayah Gubeng, Surabaya Timur',
    'RSUD Dr. Soetomo, Surabaya',
    (SELECT id FROM regions WHERE name = 'Gubeng'),
    '+62 811 3452 900',
    'Jl. Arief Rahman Hakim No.99, Sukolilo, Surabaya',
    true
)
ON CONFLICT (email) DO NOTHING;
