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

        // Sync treatment phase on the active adherence record
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var adherence = await _db.MedicationAdherences
            .FirstOrDefaultAsync(m => m.PatientId == id && m.Status == "active", ct);

        if (adherence != null)
        {
            if (dto.TreatmentPhase >= 2 && !(adherence.Phase2StartDate.HasValue && today >= adherence.Phase2StartDate.Value))
            {
                adherence.Phase2StartDate = today;
                adherence.UpdatedAt = DateTime.UtcNow;
            }
        }

        await _db.SaveChangesAsync(ct);

        return await GetByIdAsync(id, ct)
            ?? throw new InvalidOperationException("Patient missing after update");
    }

    public async Task<PatientDetailDto> CreateAsync(CreatePatientDto dto, Guid createdBy, CancellationToken ct = default)
    {
        var today = DateOnly.FromDateTime(DateTime.UtcNow);

        var phase1Start = today;
        var phase1End = phase1Start.AddMonths(2);
        // Phase 2 starts immediately if the patient is already in phase 2
        var phase2Start = dto.TreatmentPhase >= 2 ? today : phase1End;
        var phase2End = phase2Start.AddMonths(4);

        var patientId = Guid.NewGuid();

        _db.Patients.Add(new Domain.Entities.Patient
        {
            Id = patientId,
            Nik = dto.Nik,
            FullName = dto.FullName,
            Dob = dto.Dob,
            Phone = dto.Phone,
            RegionId = dto.RegionId,
            RegisteredByUserId = createdBy,
            RegisteredAt = DateTime.UtcNow,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        });

        _db.MedicationAdherences.Add(new Domain.Entities.MedicationAdherence
        {
            Id = Guid.NewGuid(),
            PatientId = patientId,
            Phase1StartDate = phase1Start,
            Phase1EndDate = phase1End,
            Phase2StartDate = phase2Start,
            Phase2EndDate = phase2End,
            Status = "active",
            CreatedByUserId = createdBy,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        });

        await _db.SaveChangesAsync(ct);

        return await GetByIdAsync(patientId, ct)
            ?? throw new InvalidOperationException("Patient missing after create");
    }

    public async Task DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var patient = await _db.Patients
            .Include(p => p.MedicationAdherences)
                .ThenInclude(a => a.AdherenceLogs)
            .FirstOrDefaultAsync(p => p.Id == id, ct)
            ?? throw new KeyNotFoundException($"Patient {id} not found");

        foreach (var adherence in patient.MedicationAdherences)
            _db.AdherenceLogs.RemoveRange(adherence.AdherenceLogs);

        _db.MedicationAdherences.RemoveRange(patient.MedicationAdherences);
        _db.Patients.Remove(patient);
        await _db.SaveChangesAsync(ct);
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

            // Show progress within the current phase only
            if (inPhase2)
            {
                var phaseStart = active.Phase2StartDate!.Value;
                var phaseEnd = active.Phase2EndDate ?? phaseStart.AddMonths(4);
                var daysElapsed = today.DayNumber - phaseStart.DayNumber;
                currentMonth = Math.Max(1, daysElapsed / 30 + 1);
                var totalDays = phaseEnd.DayNumber - phaseStart.DayNumber;
                totalMonths = Math.Max(1, (totalDays + 15) / 30); // ~4
            }
            else
            {
                var phaseStart = active.Phase1StartDate;
                var phaseEnd = active.Phase1EndDate;
                var daysElapsed = today.DayNumber - phaseStart.DayNumber;
                currentMonth = Math.Max(1, daysElapsed / 30 + 1);
                var totalDays = phaseEnd.DayNumber - phaseStart.DayNumber;
                totalMonths = Math.Max(1, (totalDays + 15) / 30); // ~2
            }
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
