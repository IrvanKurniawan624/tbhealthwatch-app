namespace TBHealthWatch.Domain.Entities;

public class DailyMedicationTarget
{
    public Guid Id { get; set; }
    public DateOnly TargetDate { get; set; }
    public string? Notes { get; set; }
    public Guid? CreatedByUserId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public ICollection<DailyMedicationTargetItem> Items { get; set; } = new List<DailyMedicationTargetItem>();
}
