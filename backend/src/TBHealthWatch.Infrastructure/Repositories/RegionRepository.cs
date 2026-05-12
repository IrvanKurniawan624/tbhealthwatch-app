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
}
