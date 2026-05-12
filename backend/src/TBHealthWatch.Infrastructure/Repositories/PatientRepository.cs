using Microsoft.EntityFrameworkCore;
using TBHealthWatch.Application.DTOs.Patient;
using TBHealthWatch.Application.Interfaces;
using TBHealthWatch.Infrastructure.Persistence;

namespace TBHealthWatch.Infrastructure.Repositories;

public class PatientRepository : IPatientRepository
{
    private readonly AppDbContext _db;

    public PatientRepository(AppDbContext db) => _db = db;

    public async Task<IReadOnlyList<PatientListItemDto>> ListAsync(CancellationToken ct = default)
    {
        var today = DateOnly.FromDateTime(DateTime.UtcNow);

        var patients = await _db.Patients
            .Include(p => p.Region)
            .Include(p => p.MedicationAdherences.Where(m => m.Status == "active"))
            .OrderBy(p => p.FullName)
            .ToListAsync(ct);

        return patients.Select(p => BuildListItem(p, today)).ToList().AsReadOnly();
    }

    public async Task<PatientDetailDto?> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var today = DateOnly.FromDateTime(DateTime.UtcNow);

        var patient = await _db.Patients
            .Include(p => p.Region)
            .Include(p => p.MedicationAdherences.Where(m => m.Status == "active"))
            .FirstOrDefaultAsync(p => p.Id == id, ct);

        if (patient == null) return null;

        var listItem = BuildListItem(patient, today);
        return new PatientDetailDto
        {
            Id = listItem.Id,
            Nik = listItem.Nik,
            Name = listItem.Name,
            Status = listItem.Status,
            Location = listItem.Location,
            Phase = listItem.Phase,
            CurrentMonth = listItem.CurrentMonth,
            TotalMonths = listItem.TotalMonths,
            Phone = patient.Phone,
            Address = patient.Address,
            Dob = patient.Dob,
            RegionName = patient.Region?.Name,
            PhotoUrl = patient.PhotoUrl
        };
    }

    public async Task<PatientDetailDto> UpdateAsync(Guid id, UpdatePatientDto dto, CancellationToken ct = default)
    {
        var patient = await _db.Patients.FindAsync(new object[] { id }, ct)
            ?? throw new KeyNotFoundException($"Patient {id} not found");

        patient.FullName = dto.FullName;
        patient.Dob = dto.Dob;
        patient.RegionId = dto.RegionId;
        patient.Phone = dto.Phone;
        patient.Address = dto.Address;
        patient.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync(ct);

        return await GetByIdAsync(id, ct)
            ?? throw new InvalidOperationException("Patient missing after update");
    }

    private static PatientListItemDto BuildListItem(Domain.Entities.Patient p, DateOnly today)
    {
        var active = p.MedicationAdherences.FirstOrDefault(m => m.Status == "active");

        string status = active != null ? "DALAM PERAWATAN" : "STABLE";
        string phase = "PHASE 1 PERAWATAN";
        int currentMonth = 1;
        int totalMonths = 6;

        if (active != null)
        {
            bool inPhase2 = active.Phase2StartDate.HasValue && today >= active.Phase2StartDate.Value;
            phase = inPhase2 ? "PHASE 2 PERAWATAN" : "PHASE 1 PERAWATAN";

            var treatmentStart = active.Phase1StartDate;
            var treatmentEnd = active.Phase2EndDate ?? active.Phase1EndDate;

            // Which month of total treatment are we in?
            var daysElapsed = today.DayNumber - treatmentStart.DayNumber;
            currentMonth = Math.Max(1, daysElapsed / 30 + 1);

            var totalDays = treatmentEnd.DayNumber - treatmentStart.DayNumber;
            totalMonths = Math.Max(1, (totalDays + 15) / 30);
        }

        return new PatientListItemDto
        {
            Id = p.Id,
            Nik = p.Nik ?? string.Empty,
            Name = p.FullName,
            Status = status,
            Location = p.Region != null ? $"{p.Region.Name}, {p.Region.Kota}" : string.Empty,
            Phase = phase,
            CurrentMonth = currentMonth,
            TotalMonths = totalMonths
        };
    }
}
