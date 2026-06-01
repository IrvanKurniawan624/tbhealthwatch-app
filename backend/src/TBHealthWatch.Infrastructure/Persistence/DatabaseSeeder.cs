using Microsoft.EntityFrameworkCore;
using TBHealthWatch.Domain.Entities;

namespace TBHealthWatch.Infrastructure.Persistence;

public static class DatabaseSeeder
{
    public static async Task SeedAsync(AppDbContext db)
    {
        await SeedRegionsAsync(db);
        await SeedUsersAsync(db);
        await SeedPatientsAsync(db);
    }

    private static async Task SeedRegionsAsync(AppDbContext db)
    {
        if (await db.Regions.AnyAsync()) return;

        var kecamatan = new[]
        {
            ("Asemrowo",        "SURABAYA.ASEMROWO"),
            ("Benowo",          "SURABAYA.BENOWO"),
            ("Bubutan",         "SURABAYA.BUBUTAN"),
            ("Bulak",           "SURABAYA.BULAK"),
            ("Dukuh Pakis",     "SURABAYA.DUKUH_PAKIS"),
            ("Gayungan",        "SURABAYA.GAYUNGAN"),
            ("Genteng",         "SURABAYA.GENTENG"),
            ("Gubeng",          "SURABAYA.GUBENG"),
            ("Gunung Anyar",    "SURABAYA.GUNUNG_ANYAR"),
            ("Jambangan",       "SURABAYA.JAMBANGAN"),
            ("Karang Pilang",   "SURABAYA.KARANG_PILANG"),
            ("Kenjeran",        "SURABAYA.KENJERAN"),
            ("Krembangan",      "SURABAYA.KREMBANGAN"),
            ("Lakarsantri",     "SURABAYA.LAKARSANTRI"),
            ("Mulyorejo",       "SURABAYA.MULYOREJO"),
            ("Pabean Cantian",  "SURABAYA.PABEAN_CANTIAN"),
            ("Pakal",           "SURABAYA.PAKAL"),
            ("Rungkut",         "SURABAYA.RUNGKUT"),
            ("Sambikerep",      "SURABAYA.SAMBIKEREP"),
            ("Sawahan",         "SURABAYA.SAWAHAN"),
            ("Semampir",        "SURABAYA.SEMAMPIR"),
            ("Simokerto",       "SURABAYA.SIMOKERTO"),
            ("Sukolilo",        "SURABAYA.SUKOLILO"),
            ("Sukomanunggal",   "SURABAYA.SUKOMANUNGGAL"),
            ("Tambaksari",      "SURABAYA.TAMBAKSARI"),
            ("Tandes",          "SURABAYA.TANDES"),
            ("Tegalsari",       "SURABAYA.TEGALSARI"),
            ("Tenggilis Mejoyo","SURABAYA.TENGGILIS_MEJOYO"),
            ("Wiyung",          "SURABAYA.WIYUNG"),
            ("Wonocolo",        "SURABAYA.WONOCOLO"),
            ("Wonokromo",       "SURABAYA.WONOKROMO"),
        };

        foreach (var (name, code) in kecamatan)
        {
            db.Regions.Add(new Region
            {
                Id = Guid.NewGuid(),
                Name = name,
                Code = code,
                Kota = "Surabaya",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            });
        }

        await db.SaveChangesAsync();
    }

    private static async Task SeedUsersAsync(AppDbContext db)
    {
        if (await db.Users.AnyAsync()) return;

        var gubeng = await db.Regions.FirstOrDefaultAsync(r => r.Code == "SURABAYA.GUBENG");

        db.Users.Add(new User
        {
            Id = new Guid("00000000-0000-0000-0000-000000000001"),
            Email = "admin@gmail.com",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("admin"),
            FullName = "Dr. Andy",
            Specialization = "Epidemiology Specialist",
            FacilityName = "RSUD Dr. Soetomo",
            FacilityRole = "Koordinator Pemantauan Wilayah Gubeng, Surabaya Timur",
            AssignmentLocation = "RSUD Dr. Soetomo, Surabaya",
            RegionId = gubeng?.Id,
            Phone = "+62 811 3452 900",
            Address = "Jl. Arief Rahman Hakim No.99, Sukolilo, Surabaya",
            IsVerified = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        });

        await db.SaveChangesAsync();
    }

    private static async Task SeedPatientsAsync(AppDbContext db)
    {
        // Re-seed when data is stale (< 50 patients means old seed)
        var existingCount = await db.Patients.IgnoreQueryFilters().CountAsync();
        if (existingCount >= 50) return;

        if (existingCount > 0)
            await db.Database.ExecuteSqlRawAsync("TRUNCATE patients CASCADE");

        var registeredBy = await db.Users.Select(u => u.Id).FirstAsync();
        var today = DateOnly.FromDateTime(DateTime.UtcNow);

        // Distribution: realistic TB hotspot pattern in Surabaya
        // ≥50 = high risk, 20–49 = warning, <20 = stable
        var regionTargets = new[]
        {
            ("SURABAYA.WONOKROMO",      58),
            ("SURABAYA.KENJERAN",       54),
            ("SURABAYA.TAMBAKSARI",     52),
            ("SURABAYA.SEMAMPIR",       50),
            ("SURABAYA.TEGALSARI",      38),
            ("SURABAYA.SIMOKERTO",      32),
            ("SURABAYA.GUBENG",         27),
            ("SURABAYA.SAWAHAN",        25),
            ("SURABAYA.PABEAN_CANTIAN", 22),
            ("SURABAYA.GENTENG",        20),
            ("SURABAYA.RUNGKUT",        16),
            ("SURABAYA.BULAK",          13),
            ("SURABAYA.BUBUTAN",        11),
            ("SURABAYA.WIYUNG",          9),
            ("SURABAYA.SUKOLILO",        7),
            ("SURABAYA.KREMBANGAN",      5),
        };

        var firstNames = new[]
        {
            "Siti", "Ahmad", "Nur", "Muhammad", "Rina", "Budi", "Dewi", "Eko", "Fitri", "Hendra",
            "Indah", "Joko", "Kartini", "Lestari", "Mira", "Nanda", "Okta", "Putri", "Rahma", "Surya",
            "Tri", "Udin", "Vina", "Wati", "Yuli", "Zahra", "Agus", "Bagas", "Cahya", "Dina"
        };

        var lastNames = new[]
        {
            "Wulandari", "Santoso", "Pratama", "Kusuma", "Rahmat", "Hidayat", "Setiawan", "Permata",
            "Wijaya", "Nugroho", "Purnama", "Sari", "Rahayu", "Susanto", "Utami",
            "Aditya", "Budiman", "Cahaya", "Darmawan", "Effendi"
        };

        int globalIdx = 0;

        foreach (var (regionCode, targetCount) in regionTargets)
        {
            var region = await db.Regions.FirstOrDefaultAsync(r => r.Code == regionCode);
            if (region == null) continue;

            for (int i = 0; i < targetCount; i++)
            {
                globalIdx++;

                var gender = (globalIdx % 2 == 0) ? 'M' : 'F';
                var firstName = firstNames[(globalIdx - 1) % firstNames.Length];
                var lastName = lastNames[((globalIdx - 1) / firstNames.Length) % lastNames.Length];
                var nik = $"3578{globalIdx:D12}";
                var birthYear = 1965 + (globalIdx % 35);
                var dob = new DateOnly(birthYear, (globalIdx % 12) + 1, Math.Min((globalIdx % 28) + 1, 28));
                var phone = $"+62 8{(globalIdx % 8) + 11} {(1000 + globalIdx % 8000):D4} {(1000 + globalIdx * 7 % 8000):D4}";

                // Last 3 patients in high-risk regions are "newly registered" (last 6 days)
                var isRecent = targetCount >= 50 && i >= targetCount - 3;
                var registeredAt = isRecent
                    ? DateTime.UtcNow.AddDays(-((globalIdx % 5) + 1))
                    : DateTime.UtcNow.AddMonths(-4).AddDays(-(globalIdx % 60));

                var regDate = DateOnly.FromDateTime(registeredAt);
                var phase1Start = regDate;
                var phase1End = phase1Start.AddMonths(2);
                var phase2Start = phase1End;
                var phase2End = phase2Start.AddMonths(4);

                var patientId = Guid.NewGuid();
                var adherenceId = Guid.NewGuid();

                db.Patients.Add(new Patient
                {
                    Id = patientId,
                    Nik = nik,
                    FullName = $"{firstName} {lastName}",
                    Dob = dob,
                    Gender = gender,
                    Phone = phone,
                    Address = $"Jl. {region.Name} No.{globalIdx}, Surabaya",
                    RegionId = region.Id,
                    RegisteredByUserId = registeredBy,
                    RegisteredAt = registeredAt,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                });

                db.MedicationAdherences.Add(new MedicationAdherence
                {
                    Id = adherenceId,
                    PatientId = patientId,
                    Phase1StartDate = phase1Start,
                    Phase1EndDate = phase1End,
                    Phase2StartDate = phase2Start,
                    Phase2EndDate = phase2End,
                    Status = "active",
                    CreatedByUserId = registeredBy,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                });

                // Adherence logs — capped at 30 days, skip for very new patients
                var logStart = phase1Start;
                var logEnd = today.AddDays(-1);
                if (logStart < logEnd)
                {
                    if ((logEnd.DayNumber - logStart.DayNumber) > 30)
                        logStart = logEnd.AddDays(-30);

                    var rng = new Random(nik.GetHashCode());
                    for (var logDay = logStart; logDay <= logEnd; logDay = logDay.AddDays(1))
                    {
                        var roll = rng.Next(100);
                        var status = roll < 84 ? "taken" : roll < 94 ? "missed" : "partial";
                        db.AdherenceLogs.Add(new AdherenceLog
                        {
                            Id = Guid.NewGuid(),
                            MedicationAdherenceId = adherenceId,
                            LogDate = logDay,
                            Phase = logDay >= phase2Start ? "phase_2" : "phase_1",
                            Status = status,
                            RecordedByUserId = registeredBy,
                            CreatedAt = DateTime.UtcNow,
                            UpdatedAt = DateTime.UtcNow
                        });
                    }
                }
            }

            await db.SaveChangesAsync();
        }
    }
}
