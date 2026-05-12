namespace TBHealthWatch.Application.DTOs.Patient;

public class PatientDetailDto : PatientListItemDto
{
    public string? Phone { get; set; }
    public string? Address { get; set; }
    public DateOnly? Dob { get; set; }
    public string? RegionName { get; set; }
    public string? PhotoUrl { get; set; }
}
