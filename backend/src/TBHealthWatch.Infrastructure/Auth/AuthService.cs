using Microsoft.EntityFrameworkCore;
using TBHealthWatch.Application.DTOs.Auth;
using TBHealthWatch.Application.Interfaces;
using TBHealthWatch.Domain.Entities;
using TBHealthWatch.Infrastructure.Persistence;

namespace TBHealthWatch.Infrastructure.Auth;

public class AuthService : IAuthService
{
    private readonly AppDbContext _db;
    private readonly IPasswordHasher _hasher;
    private readonly IJwtTokenService _jwt;

    public AuthService(AppDbContext db, IPasswordHasher hasher, IJwtTokenService jwt)
    {
        _db = db; _hasher = hasher; _jwt = jwt;
    }

    public async Task<AuthResponse> RegisterAsync(RegisterRequest request, CancellationToken ct = default)
    {
        if (await _db.Users.AnyAsync(u => u.Email == request.Email, ct))
            throw new InvalidOperationException("Email already registered");

        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = request.Email,
            PasswordHash = _hasher.Hash(request.Password),
            FullName = request.FullName,
            Specialization = request.Specialization,
            FacilityName = request.FacilityName,
            FacilityRole = request.FacilityRole,
            AssignmentLocation = request.AssignmentLocation,
            RegionId = request.RegionId,
            Phone = request.Phone,
            Address = request.Address,
            IsVerified = false,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        _db.Users.Add(user);
        await _db.SaveChangesAsync(ct);

        return await IssueTokensAsync(user, ct);
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest request, CancellationToken ct = default)
    {
        var user = await _db.Users
            .FirstOrDefaultAsync(u => u.Email == request.Email, ct);

        if (user == null || !_hasher.Verify(request.Password, user.PasswordHash))
            throw new UnauthorizedAccessException("Invalid credentials");

        user.LastLoginAt = DateTime.UtcNow;
        user.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(ct);

        return await IssueTokensAsync(user, ct);
    }

    public async Task<AuthResponse> RefreshAsync(RefreshTokenRequest request, CancellationToken ct = default)
    {
        var tokenHash = _jwt.HashToken(request.RefreshToken);
        var stored = await _db.RefreshTokens
            .Include(r => r.User)
            .FirstOrDefaultAsync(r => r.TokenHash == tokenHash, ct);

        if (stored == null || stored.ExpiresAt < DateTime.UtcNow || stored.RevokedAt != null)
            throw new UnauthorizedAccessException("Invalid or expired refresh token");

        stored.RevokedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(ct);

        return await IssueTokensAsync(stored.User!, ct);
    }

    public async Task LogoutAsync(Guid userId, CancellationToken ct = default)
    {
        var tokens = await _db.RefreshTokens
            .Where(r => r.UserId == userId && r.RevokedAt == null && r.ExpiresAt > DateTime.UtcNow)
            .ToListAsync(ct);

        foreach (var t in tokens)
            t.RevokedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync(ct);
    }

    private async Task<AuthResponse> IssueTokensAsync(User user, CancellationToken ct)
    {
        var accessToken = _jwt.GenerateAccessToken(user.Id, user.Email);
        var refreshToken = _jwt.GenerateRefreshToken();

        _db.RefreshTokens.Add(new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            TokenHash = _jwt.HashToken(refreshToken),
            ExpiresAt = DateTime.UtcNow.AddDays(30),
            CreatedAt = DateTime.UtcNow
        });
        await _db.SaveChangesAsync(ct);

        return new AuthResponse
        {
            AccessToken = accessToken,
            RefreshToken = refreshToken,
            User = new UserSummaryDto
            {
                Id = user.Id,
                Email = user.Email,
                FullName = user.FullName
            }
        };
    }
}
