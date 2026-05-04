using Microsoft.AspNetCore.Mvc;

namespace TBHealthWatch.Api.Controllers;

[ApiController]
[Route("api/monitoring")]
public class MonitoringController : ControllerBase
{
    [HttpGet("targets")]
    public IActionResult ListTargets() => Ok(new { message = "Monitoring endpoint — not yet implemented" });
}
