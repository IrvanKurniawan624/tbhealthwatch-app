using TBHealthWatch.Application.DTOs.Region;

namespace TBHealthWatch.Application.Interfaces;

public interface IRegionRepository
{
    Task<IReadOnlyList<RegionDto>> ListAsync(CancellationToken ct = default);
    Task<IReadOnlyList<RegionStatsDto>> ListStatsAsync(
        string? search = null,
        int? page = null,
        int? pageSize = null,
        CancellationToken ct = default);
}
