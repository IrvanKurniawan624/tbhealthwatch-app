namespace TBHealthWatch.Domain.Entities;

public class DailyMedicationTargetItem
{
    public Guid Id { get; set; }
    public Guid TargetId { get; set; }
    public Guid MedicationId { get; set; }
    public int? DosageMg { get; set; }
    public short? Sequence { get; set; }

    public DailyMedicationTarget? Target { get; set; }
    public Medication? Medication { get; set; }
}
