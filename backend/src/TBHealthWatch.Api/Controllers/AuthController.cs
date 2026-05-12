using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TBHealthWatch.Application.DTOs.Auth;
using TBHealthWatch.Application.Interfaces;

namespace TBHealthWatch.Api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _auth;
    private readonly ICurrentUserService _currentUser;

    public AuthController(IAuthService auth, ICurrentUserService currentUser)
    {
        _auth = auth;
        _currentUser = currentUser;
    }

    [HttpPost("register")]
    public async Task<ActionResult<AuthResponse>> Register(
        [FromBody] RegisterRequest request, CancellationToken ct)
    {
        try
        {
            return Ok(await _auth.RegisterAsync(request, ct));
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(new { message = ex.Message });
        }
    }

    [HttpPost("login")]
    public async Task<ActionResult<AuthResponse>> Login(
        [FromBody] LoginRequest request, CancellationToken ct)
    {
        try
        {
            return Ok(await _auth.LoginAsync(request, ct));
        }
        catch (UnauthorizedAccessException)
        {
            return Unauthorized(new { message = "Invalid email or password" });
        }
    }

    [HttpPost("refresh")]
    public async Task<ActionResult<AuthResponse>> Refresh(
        [FromBody] RefreshTokenRequest request, CancellationToken ct)
    {
        try
        {
            return Ok(await _auth.RefreshAsync(request, ct));
        }
        catch (UnauthorizedAccessException)
        {
            return Unauthorized(new { message = "Invalid or expired refresh token" });
        }
    }

    [Authorize]
    [HttpPost("logout")]
    public async Task<IActionResult> Logout(CancellationToken ct)
    {
        await _auth.LogoutAsync(_currentUser.UserId, ct);
        return NoContent();
    }
}
