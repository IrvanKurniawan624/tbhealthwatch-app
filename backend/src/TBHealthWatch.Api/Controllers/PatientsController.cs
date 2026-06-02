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
    private readonly ICurrentUserService _currentUser;

    public PatientsController(IPatientRepository patients, ICurrentUserService currentUser)
    {
        _patients = patients;
        _currentUser = currentUser;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<PatientListItemDto>>> List(
        [FromQuery] string? search,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        [FromQuery] string? phase = null,
        [FromQuery] string? status = null,
        [FromQuery] string? sortBy = null,
        CancellationToken ct = default)
        => Ok(await _patients.ListAsync(search, page, pageSize, phase, status, sortBy, ct));

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<PatientDetailDto>> GetById(Guid id, CancellationToken ct)
    {
        var patient = await _patients.GetByIdAsync(id, ct);
        return patient is null ? NotFound() : Ok(patient);
    }

    [HttpPost]
    public async Task<ActionResult<PatientDetailDto>> Create(
        [FromBody] CreatePatientDto dto, CancellationToken ct)
    {
        var created = await _patients.CreateAsync(dto, _currentUser.UserId, ct);
        return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
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

    [HttpDelete("{id:guid}")]
    public async Task<ActionResult> Delete(Guid id, CancellationToken ct)
    {
        try
        {
            await _patients.DeleteAsync(id, ct);
            return NoContent();
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }
}
