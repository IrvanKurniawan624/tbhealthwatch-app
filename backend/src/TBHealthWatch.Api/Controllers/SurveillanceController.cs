using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TBHealthWatch.Application.DTOs.Surveillance;
using TBHealthWatch.Application.Interfaces;

namespace TBHealthWatch.Api.Controllers;

[ApiController]
[Route("api/surveillance")]
[Authorize]
public class SurveillanceController : ControllerBase
{
    private readonly ISurveillanceRepository _surveillance;

    public SurveillanceController(ISurveillanceRepository surveillance) => _surveillance = surveillance;

    [HttpGet("summary")]
    public async Task<ActionResult<SurveillanceSummaryDto>> Summary(CancellationToken ct)
        => Ok(await _surveillance.GetSummaryAsync(ct));
}
