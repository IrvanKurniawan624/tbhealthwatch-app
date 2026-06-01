using Microsoft.EntityFrameworkCore;
using TBHealthWatch.Application.DTOs.Surveillance;
using TBHealthWatch.Application.Interfaces;
using TBHealthWatch.Infrastructure.Persistence;

namespace TBHealthWatch.Infrastructure.Repositories;

public class SurveillanceRepository : ISurveillanceRepository
{
    private readonly AppDbContext _db;

    public SurveillanceRepository(AppDbContext db) => _db = db;

    public async Task<SurveillanceSummaryDto> GetSummaryAsync(CancellationToken ct = default)
    {
        var now = DateTime.UtcNow;
        var monthStart = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var sevenDaysAgo = now.AddDays(-7);

        var totalActive = await _db.Patients.CountAsync(ct);

        var newCasesThisMonth = await _db.Patients
            .CountAsync(p => p.RegisteredAt != null && p.RegisteredAt >= monthStart, ct);

        // Patient count per region (ordered by count desc)
        var regionCounts = await (
            from p in _db.Patients
            where p.RegionId != null
            join r in _db.Regions on p.RegionId equals r.Id
            group p by r.Name into g
            orderby g.Count() descending
            select new { Name = g.Key, Count = g.Count() }
        ).ToListAsync(ct);

        // Newly registered patients in last 7 days, grouped by region
        var recentByRegion = await (
            from p in _db.Patients
            where p.RegionId != null && p.RegisteredAt != null && p.RegisteredAt >= sevenDaysAgo
            join r in _db.Regions on p.RegionId equals r.Id
            group p by r.Name into g
            orderby g.Count() descending
            select new { Name = g.Key, Count = g.Count() }
        ).ToListAsync(ct);

        var totalLogs = await _db.AdherenceLogs.CountAsync(ct);
        var takenLogs = await _db.AdherenceLogs.CountAsync(l => l.Status == "taken", ct);
        var complianceRate = totalLogs > 0
            ? Math.Round((double)takenLogs / totalLogs * 100, 1)
            : 0.0;

        var highRiskCount = regionCounts.Count(r => r.Count >= 50);

        var topRegions = regionCounts.Take(5).Select(r => new SurveillanceRegionSummaryDto
        {
            Name = r.Name,
            PatientCount = r.Count,
            RiskLevel = RiskLabel(r.Count)
        }).ToList();

        // Build prioritised alerts
        var alerts = new List<SurveillanceAlertDto>();
        var shownRegions = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        // P1: High-risk clusters (≥50 patients)
        foreach (var r in regionCounts.Where(x => x.Count >= 50).Take(3))
        {
            alerts.Add(new SurveillanceAlertDto
            {
                Title = "Klaster Terdeteksi",
                Description = $"Klaster baru sebanyak {r.Count} pasien teridentifikasi di wilayah {r.Name}.",
                Type = "high"
            });
            shownRegions.Add(r.Name);
        }

        // P2a: Total new patients in last 7 days (includes patients without region)
        var totalNew = await _db.Patients
            .CountAsync(p => p.RegisteredAt != null && p.RegisteredAt >= sevenDaysAgo, ct);
        if (totalNew > 0)
        {
            alerts.Add(new SurveillanceAlertDto
            {
                Title = "Pasien Baru Terdaftar",
                Description = $"Terdapat {totalNew} pasien baru terdaftar dalam 7 hari terakhir.",
                Type = totalNew >= 5 ? "high" : "warning"
            });
        }

        // P2b: Newly registered patients per region (last 7 days)
        foreach (var r in recentByRegion.Take(3))
        {
            alerts.Add(new SurveillanceAlertDto
            {
                Title = "Pasien Baru",
                Description = $"Terdapat {r.Count} pasien baru terdaftar di wilayah {r.Name}.",
                Type = r.Count >= 3 ? "high" : "warning"
            });
            shownRegions.Add(r.Name);
        }

        // P3: Warning regions not yet listed (20–49 patients)
        foreach (var r in regionCounts.Where(x => x.Count >= 20 && x.Count < 50 && !shownRegions.Contains(x.Name)).Take(2))
        {
            alerts.Add(new SurveillanceAlertDto
            {
                Title = "Peringatan Wilayah",
                Description = $"{r.Name} memiliki {r.Count} pasien aktif — perlu pemantauan intensif.",
                Type = "warning"
            });
            shownRegions.Add(r.Name);
        }

        // P4: Top impacted region update (always appended)
        if (regionCounts.Count > 0)
        {
            var top = regionCounts[0];
            alerts.Add(new SurveillanceAlertDto
            {
                Title = "Update Wilayah Terdampak",
                Description = $"{top.Name} menjadi wilayah paling terdampak dengan {top.Count} pasien aktif.",
                Type = "warning"
            });
        }

        return new SurveillanceSummaryDto
        {
            TotalActive = totalActive,
            NewCasesThisMonth = newCasesThisMonth,
            HighRiskCount = highRiskCount,
            ComplianceRate = complianceRate,
            TopRegions = topRegions,
            Alerts = alerts
        };
    }

    private static string RiskLabel(int count) =>
        count >= 50 ? "high" : count >= 20 ? "warning" : "stable";
}
