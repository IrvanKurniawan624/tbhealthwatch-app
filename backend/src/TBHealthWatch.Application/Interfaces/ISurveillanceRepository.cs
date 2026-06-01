using TBHealthWatch.Application.DTOs.Surveillance;

namespace TBHealthWatch.Application.Interfaces;

public interface ISurveillanceRepository
{
    Task<SurveillanceSummaryDto> GetSummaryAsync(CancellationToken ct = default);
}
