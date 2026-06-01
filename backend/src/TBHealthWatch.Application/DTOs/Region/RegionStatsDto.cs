namespace TBHealthWatch.Application.DTOs.Region;

public class RegionStatsDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int PatientCount { get; set; }
    public string RiskLevel { get; set; } = string.Empty;
}
