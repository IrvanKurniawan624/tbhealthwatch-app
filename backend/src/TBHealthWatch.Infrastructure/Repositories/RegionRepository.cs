using Microsoft.EntityFrameworkCore;
using TBHealthWatch.Application.DTOs.Region;
using TBHealthWatch.Application.Interfaces;
using TBHealthWatch.Infrastructure.Persistence;

namespace TBHealthWatch.Infrastructure.Repositories;

public class RegionRepository : IRegionRepository
{
    private readonly AppDbContext _db;

    public RegionRepository(AppDbContext db) => _db = db;

    public async Task<IReadOnlyList<RegionDto>> ListAsync(CancellationToken ct = default)
    {
        return await _db.Regions
            .OrderBy(r => r.Name)
            .Select(r => new RegionDto
            {
                Id = r.Id,
                Name = r.Name,
                Code = r.Code,
                Kota = r.Kota
            })
            .ToListAsync(ct);
    }

    public async Task<IReadOnlyList<RegionStatsDto>> ListStatsAsync(CancellationToken ct = default)
    {
        var counts = await _db.Patients
            .Where(p => p.RegionId != null)
            .GroupBy(p => p.RegionId!.Value)
            .Select(g => new { RegionId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.RegionId, x => x.Count, ct);

        var regions = await _db.Regions.OrderBy(r => r.Name).ToListAsync(ct);

        return regions.Select(r =>
        {
            var count = counts.GetValueOrDefault(r.Id, 0);
            return new RegionStatsDto
            {
                Id = r.Id,
                Name = r.Name,
                PatientCount = count,
                RiskLevel = count >= 50 ? "high" : count >= 20 ? "warning" : "stable"
            };
        }).ToList().AsReadOnly();
    }
}
