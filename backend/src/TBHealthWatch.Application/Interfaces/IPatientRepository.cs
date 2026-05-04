using TBHealthWatch.Domain.Entities;

namespace TBHealthWatch.Application.Interfaces;

public interface IPatientRepository
{
    Task<IReadOnlyList<Patient>> ListActiveAsync(CancellationToken ct = default);
    Task<Patient?> GetByIdAsync(Guid id, CancellationToken ct = default);
}
