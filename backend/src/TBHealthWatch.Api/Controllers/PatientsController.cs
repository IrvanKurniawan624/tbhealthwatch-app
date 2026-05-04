using Microsoft.AspNetCore.Mvc;

namespace TBHealthWatch.Api.Controllers;

[ApiController]
[Route("api/patients")]
public class PatientsController : ControllerBase
{
    [HttpGet]
    public IActionResult List() => Ok(new { message = "Patients endpoint — not yet implemented" });
}
