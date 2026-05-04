namespace TBHealthWatch.Domain.Entities;

public class PatientTreatment
{
    public Guid Id { get; set; }
    public Guid PatientId { get; set; }
    public DateOnly Phase1StartDate { get; set; }
    public DateOnly Phase1EndDate { get; set; }
    public DateOnly? Phase2StartDate { get; set; }
    public DateOnly? Phase2EndDate { get; set; }
    public DateOnly? TreatmentCompletedDate { get; set; }
    public string Status { get; set; } = "active";
    public string? Notes { get; set; }
    public Guid? CreatedByUserId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public Patient? Patient { get; set; }
}
