using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using TBHealthWatch.Application.Interfaces;

namespace TBHealthWatch.Infrastructure.Services;

public class CurrentUserService : ICurrentUserService
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public CurrentUserService(IHttpContextAccessor httpContextAccessor)
        => _httpContextAccessor = httpContextAccessor;

    public Guid UserId
    {
        get
        {
            var sub = _httpContextAccessor.HttpContext?.User
                          .FindFirstValue(ClaimTypes.NameIdentifier)
                      ?? _httpContextAccessor.HttpContext?.User
                          .FindFirstValue("sub");

            if (!Guid.TryParse(sub, out var id))
                throw new UnauthorizedAccessException("User not authenticated");

            return id;
        }
    }
}
