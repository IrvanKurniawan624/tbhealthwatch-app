namespace TBHealthWatch.Domain.Entities;

public class AdherenceLog
{
    public Guid Id { get; set; }
    public Guid MedicationAdherenceId { get; set; }
    public DateOnly LogDate { get; set; }
    public string Phase { get; set; } = "phase_1";
    public string Status { get; set; } = "pending";
    public string? Notes { get; set; }
    public Guid? RecordedByUserId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public MedicationAdherence? MedicationAdherence { get; set; }
}
