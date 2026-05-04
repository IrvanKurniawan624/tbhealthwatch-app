namespace TBHealthWatch.Domain.Entities;

public class PatientMedicationLog
{
    public Guid Id { get; set; }
    public Guid PatientTreatmentId { get; set; }
    public DateOnly LogDate { get; set; }
    public Guid? TargetItemId { get; set; }
    public Guid MedicationId { get; set; }
    public int? DosageMg { get; set; }
    public string Status { get; set; } = "pending";
    public DateTime? TakenAt { get; set; }
    public Guid? RecordedByUserId { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}
