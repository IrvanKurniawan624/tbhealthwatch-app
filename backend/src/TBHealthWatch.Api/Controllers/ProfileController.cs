using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TBHealthWatch.Application.DTOs;
using TBHealthWatch.Application.Interfaces;

namespace TBHealthWatch.Api.Controllers;

[ApiController]
[Route("api/profile")]
[Authorize]
public class ProfileController : ControllerBase
{
    private readonly IProfileRepository _profileRepo;
    private readonly ICurrentUserService _currentUser;

    public ProfileController(IProfileRepository profileRepo, ICurrentUserService currentUser)
    {
        _profileRepo = profileRepo;
        _currentUser = currentUser;
    }

    [HttpGet("me")]
    public async Task<ActionResult<ProfileDto>> GetMyProfile(CancellationToken ct)
    {
        var profile = await _profileRepo.GetByIdAsync(_currentUser.UserId, ct);
        return profile is null ? NotFound() : Ok(profile);
    }

    [HttpPut("me")]
    public async Task<ActionResult<ProfileDto>> UpdateMyProfile(
        [FromBody] UpdateProfileDto dto, CancellationToken ct)
    {
        try
        {
            return Ok(await _profileRepo.UpdateAsync(_currentUser.UserId, dto, ct));
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }
}
