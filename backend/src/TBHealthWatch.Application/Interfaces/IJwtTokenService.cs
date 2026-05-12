namespace TBHealthWatch.Application.Interfaces;

public interface IJwtTokenService
{
    string GenerateAccessToken(Guid userId, string email);
    string GenerateRefreshToken();
    string HashToken(string token);
}
