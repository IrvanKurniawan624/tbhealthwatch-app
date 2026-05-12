namespace TBHealthWatch.Application.DTOs.Adherence;

public class AdherenceCalendarDto
{
    public int Year { get; set; }
    public int Month { get; set; }
    public List<AdherenceDayDto> Days { get; set; } = [];
}

public class AdherenceDayDto
{
    public DateOnly Date { get; set; }
    public string Status { get; set; } = string.Empty;
}
