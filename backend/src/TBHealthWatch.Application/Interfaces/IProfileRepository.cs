using TBHealthWatch.Application.DTOs;

namespace TBHealthWatch.Application.Interfaces;

public interface IProfileRepository
{
    Task<ProfileDto?> GetByIdAsync(Guid userId, CancellationToken ct = default);
    Task<ProfileDto> UpdateAsync(Guid userId, UpdateProfileDto dto, CancellationToken ct = default);
}
