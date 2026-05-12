using TBHealthWatch.Application.DTOs.Region;

namespace TBHealthWatch.Application.Interfaces;

public interface IRegionRepository
{
    Task<IReadOnlyList<RegionDto>> ListAsync(CancellationToken ct = default);
}
