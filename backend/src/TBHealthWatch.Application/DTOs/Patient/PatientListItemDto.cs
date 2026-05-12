namespace TBHealthWatch.Application.DTOs.Patient;

public class PatientListItemDto
{
    public Guid Id { get; set; }
    public string Nik { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string Location { get; set; } = string.Empty;
    public string Phase { get; set; } = string.Empty;
    public int CurrentMonth { get; set; }
    public int TotalMonths { get; set; }
}
