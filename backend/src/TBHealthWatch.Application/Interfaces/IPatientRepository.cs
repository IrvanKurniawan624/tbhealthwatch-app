using TBHealthWatch.Application.DTOs.Patient;

namespace TBHealthWatch.Application.Interfaces;

public interface IPatientRepository
{
    Task<IReadOnlyList<PatientListItemDto>> ListAsync(CancellationToken ct = default);
    Task<PatientDetailDto?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<PatientDetailDto> UpdateAsync(Guid id, UpdatePatientDto dto, CancellationToken ct = default);
    Task<PatientDetailDto> CreateAsync(CreatePatientDto dto, Guid createdBy, CancellationToken ct = default);
    Task DeleteAsync(Guid id, CancellationToken ct = default);
}
