using Microsoft.EntityFrameworkCore;
using TBHealthWatch.Application.DTOs.Adherence;
using TBHealthWatch.Application.Interfaces;
using TBHealthWatch.Domain.Entities;
using TBHealthWatch.Infrastructure.Persistence;

namespace TBHealthWatch.Infrastructure.Repositories;

public class AdherenceRepository : IAdherenceRepository
{
    private readonly AppDbContext _db;

    public AdherenceRepository(AppDbContext db) => _db = db;

    public async Task<AdherenceSummaryDto> GetSummaryAsync(Guid patientId, CancellationToken ct = default)
    {
        var today = DateOnly.FromDateTime(DateTime.UtcNow);

        var adherence = await _db.MedicationAdherences
            .Include(m => m.AdherenceLogs)
            .Where(m => m.PatientId == patientId && m.Status == "active")
            .FirstOrDefaultAsync(ct);

        if (adherence == null) return new AdherenceSummaryDto();

        var logs = adherence.AdherenceLogs.ToList();

        // Streak: consecutive 'taken' days backwards from yesterday
        var takenDates = logs.Where(l => l.Status == "taken").Select(l => l.LogDate).ToHashSet();
        int streak = 0;
        var day = today.AddDays(-1);
        while (takenDates.Contains(day))
        {
            streak++;
            day = day.AddDays(-1);
        }

        bool inPhase2 = adherence.Phase2StartDate.HasValue && today >= adherence.Phase2StartDate.Value;
        int dosesTotal;
        int dosesTaken;
        int elapsedDays;

        if (inPhase2)
        {
            var phase2Start = adherence.Phase2StartDate!.Value;
            var phase2End = adherence.Phase2EndDate ?? phase2Start.AddMonths(4);
            dosesTotal = Math.Max(1, phase2End.DayNumber - phase2Start.DayNumber + 1);
            dosesTaken = logs.Count(l => l.Status == "taken" && l.Phase == "phase_2");
            var lastDay = today < phase2End ? today : phase2End;
            elapsedDays = Math.Max(1, lastDay.DayNumber - phase2Start.DayNumber + 1);
        }
        else
        {
            var phase1Start = adherence.Phase1StartDate;
            var phase1End = adherence.Phase1EndDate;
            dosesTotal = Math.Max(1, phase1End.DayNumber - phase1Start.DayNumber + 1);
            dosesTaken = logs.Count(l => l.Status == "taken" && l.Phase == "phase_1");
            var lastDay = today < phase1End ? today : phase1End;
            elapsedDays = Math.Max(1, lastDay.DayNumber - phase1Start.DayNumber + 1);
        }

        return new AdherenceSummaryDto
        {
            Percentage = elapsedDays > 0 ? Math.Round((decimal)dosesTaken / elapsedDays * 100, 1) : 0,
            Target = 95,
            DosesTaken = dosesTaken,
            DosesTotal = dosesTotal,
            StreakDays = streak,
            CurrentPhase = inPhase2 ? "phase_2" : "phase_1"
        };
    }

    public async Task<AdherenceCalendarDto> GetCalendarAsync(
        Guid patientId, int year, int month, CancellationToken ct = default)
    {
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var firstDay = new DateOnly(year, month, 1);
        var lastDay = new DateOnly(year, month, DateTime.DaysInMonth(year, month));

        var adherence = await _db.MedicationAdherences
            .Include(m => m.AdherenceLogs.Where(l => l.LogDate >= firstDay && l.LogDate <= lastDay))
            .Where(m => m.PatientId == patientId && m.Status == "active")
            .FirstOrDefaultAsync(ct);

        var days = new List<AdherenceDayDto>();

        for (var d = firstDay; d <= lastDay; d = d.AddDays(1))
        {
            string status;
            if (adherence == null || d < adherence.Phase1StartDate ||
                (adherence.TreatmentCompletedDate.HasValue && d > adherence.TreatmentCompletedDate.Value))
            {
                status = "outside_month";
            }
            else
            {
                var log = adherence.AdherenceLogs.FirstOrDefault(l => l.LogDate == d);
                if (log != null)
                    status = log.Status;
                else if (d > today)
                    status = "upcoming";
                else
                    status = "pending";
            }

            days.Add(new AdherenceDayDto { Date = d, Status = status });
        }

        return new AdherenceCalendarDto { Year = year, Month = month, Days = days };
    }

    public async Task LogAsync(
        Guid patientId, LogAdherenceRequest request, Guid recordedByUserId, CancellationToken ct = default)
    {
        var adherence = await _db.MedicationAdherences
            .Where(m => m.PatientId == patientId && m.Status == "active")
            .FirstOrDefaultAsync(ct)
            ?? throw new KeyNotFoundException("No active treatment for this patient");

        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        bool inPhase2 = adherence.Phase2StartDate.HasValue && today >= adherence.Phase2StartDate.Value;

        var existing = await _db.AdherenceLogs
            .FirstOrDefaultAsync(
                l => l.MedicationAdherenceId == adherence.Id && l.LogDate == request.LogDate, ct);

        if (existing != null)
        {
            existing.Status = request.Status;
            existing.Notes = request.Notes;
            existing.RecordedByUserId = recordedByUserId;
            existing.UpdatedAt = DateTime.UtcNow;
        }
        else
        {
            _db.AdherenceLogs.Add(new AdherenceLog
            {
                Id = Guid.NewGuid(),
                MedicationAdherenceId = adherence.Id,
                LogDate = request.LogDate,
                Phase = inPhase2 ? "phase_2" : "phase_1",
                Status = request.Status,
                Notes = request.Notes,
                RecordedByUserId = recordedByUserId,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            });
        }

        await _db.SaveChangesAsync(ct);
    }
}
