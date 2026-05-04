namespace TBHealthWatch.Domain.Entities;

public class Medication
{
    public Guid Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public int? DefaultDosageMg { get; set; }
    public string? Unit { get; set; }
    public string? Category { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}
