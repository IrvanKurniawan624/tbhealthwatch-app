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
            ("Asemrowo",       "SURABAYA.ASEMROWO"),
            ("Benowo",         "SURABAYA.BENOWO"),
            ("Bubutan",        "SURABAYA.BUBUTAN"),
            ("Bulak",          "SURABAYA.BULAK"),
            ("Dukuh Pakis",    "SURABAYA.DUKUH_PAKIS"),
            ("Gayungan",       "SURABAYA.GAYUNGAN"),
            ("Genteng",        "SURABAYA.GENTENG"),
            ("Gubeng",         "SURABAYA.GUBENG"),
            ("Gunung Anyar",   "SURABAYA.GUNUNG_ANYAR"),
            ("Jambangan",      "SURABAYA.JAMBANGAN"),
            ("Karang Pilang",  "SURABAYA.KARANG_PILANG"),
            ("Kenjeran",       "SURABAYA.KENJERAN"),
            ("Krembangan",     "SURABAYA.KREMBANGAN"),
            ("Lakarsantri",    "SURABAYA.LAKARSANTRI"),
            ("Mulyorejo",      "SURABAYA.MULYOREJO"),
            ("Pabean Cantian", "SURABAYA.PABEAN_CANTIAN"),
            ("Pakal",          "SURABAYA.PAKAL"),
            ("Rungkut",        "SURABAYA.RUNGKUT"),
            ("Sambikerep",     "SURABAYA.SAMBIKEREP"),
            ("Sawahan",        "SURABAYA.SAWAHAN"),
            ("Semampir",       "SURABAYA.SEMAMPIR"),
            ("Simokerto",      "SURABAYA.SIMOKERTO"),
            ("Sukolilo",       "SURABAYA.SUKOLILO"),
            ("Sukomanunggal",  "SURABAYA.SUKOMANUNGGAL"),
            ("Tambaksari",     "SURABAYA.TAMBAKSARI"),
            ("Tandes",         "SURABAYA.TANDES"),
            ("Tegalsari",      "SURABAYA.TEGALSARI"),
            ("Tenggilis Mejoyo","SURABAYA.TENGGILIS_MEJOYO"),
            ("Wiyung",         "SURABAYA.WIYUNG"),
            ("Wonocolo",       "SURABAYA.WONOCOLO"),
            ("Wonokromo",      "SURABAYA.WONOKROMO"),
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

        db.Users.Add(
            new User
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
        if (await db.Patients.AnyAsync()) return;

        var registeredBy = await db.Users.Select(u => u.Id).FirstAsync();
        var gubeng    = await db.Regions.FirstOrDefaultAsync(r => r.Code == "SURABAYA.GUBENG");
        var kenjeran  = await db.Regions.FirstOrDefaultAsync(r => r.Code == "SURABAYA.KENJERAN");
        var rungkut   = await db.Regions.FirstOrDefaultAsync(r => r.Code == "SURABAYA.RUNGKUT");
        var tambaksari= await db.Regions.FirstOrDefaultAsync(r => r.Code == "SURABAYA.TAMBAKSARI");
        var sukolilo  = await db.Regions.FirstOrDefaultAsync(r => r.Code == "SURABAYA.SUKOLILO");

        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        // Treatment started 4 months ago → currentMonth ≈ 5 of totalMonths = 6
        var phase1Start = today.AddMonths(-4);
        var phase1End   = phase1Start.AddMonths(2);
        var phase2Start = phase1End;
        var phase2End   = phase2Start.AddMonths(4);

        var patientDefs = new[]
        {
            ("3578012345678901", "Siti Aminah",    "1989-08-17", 'F', "+62 811 2323 712",   "Jl. Gubeng No.1, Surabaya",     gubeng),
            ("3578019876543210", "Aditya Pratama", "1995-03-22", 'M', "+62 812 3456 7890",  "Jl. Kenjeran No.5, Surabaya",   kenjeran),
            ("3578013344556677", "Rina Wulandari", "1992-11-05", 'F', "+62 813 9988 7766",  "Jl. Rungkut No.10, Surabaya",   rungkut),
            ("3578018877665544", "Budi Santoso",   "1987-06-14", 'M', "+62 815 4455 6677",  "Jl. Tambaksari No.3, Surabaya", tambaksari),
            ("3578015566778899", "Dewi Kusuma",    "1998-01-30", 'F', "+62 817 7788 9900",  "Jl. Sukolilo No.8, Surabaya",   sukolilo),
        };

        foreach (var (nik, name, dob, gender, phone, address, region) in patientDefs)
        {
            var patientId = Guid.NewGuid();
            db.Patients.Add(new Patient
            {
                Id = patientId,
                Nik = nik,
                FullName = name,
                Dob = DateOnly.Parse(dob),
                Gender = gender,
                Phone = phone,
                Address = address,
                RegionId = region?.Id,
                RegisteredByUserId = registeredBy,
                RegisteredAt = DateTime.UtcNow.AddMonths(-4),
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            });
        }

        await db.SaveChangesAsync();

        // Seed adherence records + 30 days of logs for each patient
        var patients = await db.Patients.ToListAsync();
        foreach (var patient in patients)
        {
            var adherenceId = Guid.NewGuid();
            db.MedicationAdherences.Add(new MedicationAdherence
            {
                Id = adherenceId,
                PatientId = patient.Id,
                Phase1StartDate = phase1Start,
                Phase1EndDate   = phase1End,
                Phase2StartDate = phase2Start,
                Phase2EndDate   = phase2End,
                Status = "active",
                CreatedByUserId = registeredBy,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            });
            await db.SaveChangesAsync();

            // Use a deterministic seed per patient for reproducible demo data
            var rng = new Random(patient.Nik!.GetHashCode());
            for (var logDay = today.AddDays(-29); logDay <= today.AddDays(-1); logDay = logDay.AddDays(1))
            {
                var roll = rng.Next(100);
                var logStatus = roll < 84 ? "taken" : roll < 94 ? "missed" : "partial";
                var inPhase2 = logDay >= phase2Start;

                db.AdherenceLogs.Add(new AdherenceLog
                {
                    Id = Guid.NewGuid(),
                    MedicationAdherenceId = adherenceId,
                    LogDate = logDay,
                    Phase = inPhase2 ? "phase_2" : "phase_1",
                    Status = logStatus,
                    RecordedByUserId = registeredBy,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                });
            }

            await db.SaveChangesAsync();
        }
    }
}
