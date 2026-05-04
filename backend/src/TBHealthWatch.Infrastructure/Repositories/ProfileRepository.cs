using Microsoft.EntityFrameworkCore;
using TBHealthWatch.Application.DTOs;
using TBHealthWatch.Application.Interfaces;
using TBHealthWatch.Infrastructure.Persistence;

namespace TBHealthWatch.Infrastructure.Repositories;

public class ProfileRepository : IProfileRepository
{
    private readonly AppDbContext _db;

    public ProfileRepository(AppDbContext db) => _db = db;

    public async Task<ProfileDto?> GetByIdAsync(Guid userId, CancellationToken ct = default)
    {
        return await _db.Users
            .Where(u => u.Id == userId)
            .Select(u => new ProfileDto
            {
                Id = u.Id,
                Email = u.Email,
                FullName = u.FullName,
                Specialization = u.Specialization,
                FacilityName = u.FacilityName,
                FacilityRole = u.FacilityRole,
                AssignmentLocation = u.AssignmentLocation,
                RegionId = u.RegionId,
                RegionName = u.Region != null ? u.Region.Name : null,
                Phone = u.Phone,
                Address = u.Address,
                AvatarUrl = u.AvatarUrl
            })
            .FirstOrDefaultAsync(ct);
    }

    public async Task<ProfileDto> UpdateAsync(Guid userId, UpdateProfileDto dto, CancellationToken ct = default)
    {
        var user = await _db.Users.FindAsync(new object[] { userId }, ct)
            ?? throw new KeyNotFoundException($"User {userId} not found");

        user.FullName = dto.FullName;
        user.Specialization = dto.Specialization;
        user.FacilityName = dto.FacilityName;
        user.FacilityRole = dto.FacilityRole;
        user.AssignmentLocation = dto.AssignmentLocation;
        user.RegionId = dto.RegionId;
        user.Phone = dto.Phone;
        user.Address = dto.Address;
        user.AvatarUrl = dto.AvatarUrl;
        user.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync(ct);

        return await GetByIdAsync(userId, ct)
            ?? throw new InvalidOperationException("Profile missing after update");
    }
}
