namespace TBHealthWatch.Application.DTOs.Adherence;

public class AdherenceSummaryDto
{
    public decimal Percentage { get; set; }
    public int Target { get; set; } = 95;
    public int DosesTaken { get; set; }
    public int DosesTotal { get; set; }
    public int StreakDays { get; set; }
    public string CurrentPhase { get; set; } = string.Empty;
}
