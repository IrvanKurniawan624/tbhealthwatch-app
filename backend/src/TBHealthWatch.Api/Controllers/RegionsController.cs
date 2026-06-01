using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TBHealthWatch.Application.DTOs.Region;
using TBHealthWatch.Application.Interfaces;

namespace TBHealthWatch.Api.Controllers;

[ApiController]
[Route("api/regions")]
[Authorize]
public class RegionsController : ControllerBase
{
    private readonly IRegionRepository _regions;

    public RegionsController(IRegionRepository regions) => _regions = regions;

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<RegionDto>>> List(CancellationToken ct)
        => Ok(await _regions.ListAsync(ct));

    [HttpGet("stats")]
    public async Task<ActionResult<IReadOnlyList<RegionStatsDto>>> Stats(CancellationToken ct)
        => Ok(await _regions.ListStatsAsync(ct));
}
