using TBHealthWatch.Application.DTOs.Adherence;

namespace TBHealthWatch.Application.Interfaces;

public interface IAdherenceRepository
{
    Task<AdherenceSummaryDto> GetSummaryAsync(Guid patientId, CancellationToken ct = default);
    Task<AdherenceCalendarDto> GetCalendarAsync(Guid patientId, int year, int month, CancellationToken ct = default);
    Task LogAsync(Guid patientId, LogAdherenceRequest request, Guid recordedByUserId, CancellationToken ct = default);
}
