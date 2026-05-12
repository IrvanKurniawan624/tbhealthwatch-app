using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TBHealthWatch.Application.DTOs.Adherence;
using TBHealthWatch.Application.Interfaces;

namespace TBHealthWatch.Api.Controllers;

[ApiController]
[Route("api/patients/{patientId:guid}/adherence")]
[Authorize]
public class AdherenceController : ControllerBase
{
    private readonly IAdherenceRepository _adherence;
    private readonly ICurrentUserService _currentUser;

    public AdherenceController(IAdherenceRepository adherence, ICurrentUserService currentUser)
    {
        _adherence = adherence;
        _currentUser = currentUser;
    }

    [HttpGet("summary")]
    public async Task<ActionResult<AdherenceSummaryDto>> GetSummary(Guid patientId, CancellationToken ct)
        => Ok(await _adherence.GetSummaryAsync(patientId, ct));

    [HttpGet("calendar")]
    public async Task<ActionResult<AdherenceCalendarDto>> GetCalendar(
        Guid patientId,
        [FromQuery] int year,
        [FromQuery] int month,
        CancellationToken ct)
    {
        if (year < 2000 || year > 2100 || month < 1 || month > 12)
            return BadRequest(new { message = "Invalid year or month" });

        return Ok(await _adherence.GetCalendarAsync(patientId, year, month, ct));
    }

    [HttpPost("log")]
    public async Task<IActionResult> Log(
        Guid patientId, [FromBody] LogAdherenceRequest request, CancellationToken ct)
    {
        try
        {
            await _adherence.LogAsync(patientId, request, _currentUser.UserId, ct);
            return NoContent();
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }
}
