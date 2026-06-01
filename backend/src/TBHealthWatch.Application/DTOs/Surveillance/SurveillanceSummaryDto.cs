namespace TBHealthWatch.Application.DTOs.Surveillance;

public class SurveillanceSummaryDto
{
    public int TotalActive { get; set; }
    public int NewCasesThisMonth { get; set; }
    public int HighRiskCount { get; set; }
    public double ComplianceRate { get; set; }
    public List<SurveillanceRegionSummaryDto> TopRegions { get; set; } = new();
    public List<SurveillanceAlertDto> Alerts { get; set; } = new();
}

public class SurveillanceRegionSummaryDto
{
    public string Name { get; set; } = string.Empty;
    public int PatientCount { get; set; }
    public string RiskLevel { get; set; } = string.Empty;
}

public class SurveillanceAlertDto
{
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
}
