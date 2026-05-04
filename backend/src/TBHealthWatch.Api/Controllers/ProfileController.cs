using Microsoft.AspNetCore.Mvc;
using TBHealthWatch.Application.DTOs;
using TBHealthWatch.Application.Interfaces;

namespace TBHealthWatch.Api.Controllers;

[ApiController]
[Route("api/profile")]
public class ProfileController : ControllerBase
{
    private readonly IProfileRepository _profileRepo;

    public ProfileController(IProfileRepository profileRepo) => _profileRepo = profileRepo;

    // TODO: replace hardcoded ID with JWT sub claim after auth is wired
    private static readonly Guid DemoUserId = Guid.Parse("00000000-0000-0000-0000-000000000001");

    [HttpGet("me")]
    public async Task<ActionResult<ProfileDto>> GetMyProfile(CancellationToken ct)
    {
        var profile = await _profileRepo.GetByIdAsync(DemoUserId, ct);
        return profile is null ? NotFound() : Ok(profile);
    }

    [HttpPut("me")]
    public async Task<ActionResult<ProfileDto>> UpdateMyProfile(
        [FromBody] UpdateProfileDto dto,
        CancellationToken ct)
    {
        try
        {
            var updated = await _profileRepo.UpdateAsync(DemoUserId, dto, ct);
            return Ok(updated);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }
}
