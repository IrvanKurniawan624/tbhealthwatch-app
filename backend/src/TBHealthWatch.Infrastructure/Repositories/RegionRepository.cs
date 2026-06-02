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

    public async Task<IReadOnlyList<RegionStatsDto>> ListStatsAsync(
        string? search = null,
        int? page = null,
        int? pageSize = null,
        CancellationToken ct = default)
    {
        var query = _db.Regions.AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(r => r.Name.ToLower().Contains(s));
        }

        query = query.OrderBy(r => r.Name);

        if (page.HasValue && pageSize.HasValue)
        {
            query = query.Skip((page.Value - 1) * pageSize.Value).Take(pageSize.Value);
        }

        var regions = await query.ToListAsync(ct);
        var regionIds = regions.Select(r => r.Id).ToList();

        var counts = await _db.Patients
            .Where(p => p.RegionId != null && regionIds.Contains(p.RegionId.Value))
            .GroupBy(p => p.RegionId!.Value)
            .Select(g => new { RegionId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.RegionId, x => x.Count, ct);

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
