using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using TBHealthWatch.Application.DTOs.Patient;
using TBHealthWatch.Application.Interfaces;

namespace TBHealthWatch.Api.Controllers;

[ApiController]
[Route("api/patients")]
[Authorize]
public class PatientsController : ControllerBase
{
    private readonly IPatientRepository _patients;

    public PatientsController(IPatientRepository patients) => _patients = patients;

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<PatientListItemDto>>> List(CancellationToken ct)
        => Ok(await _patients.ListAsync(ct));

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<PatientDetailDto>> GetById(Guid id, CancellationToken ct)
    {
        var patient = await _patients.GetByIdAsync(id, ct);
        return patient is null ? NotFound() : Ok(patient);
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<PatientDetailDto>> Update(
        Guid id, [FromBody] UpdatePatientDto dto, CancellationToken ct)
    {
        try
        {
            return Ok(await _patients.UpdateAsync(id, dto, ct));
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }
}
