using System.ComponentModel.DataAnnotations;

namespace TBHealthWatch.Application.DTOs.Patient;

public class CreatePatientDto
{
    [Required, MaxLength(200)] public string FullName { get; set; } = string.Empty;
    public string? Nik { get; set; }
    public DateOnly? Dob { get; set; }
    public string? Phone { get; set; }
    public Guid? RegionId { get; set; }
    public int TreatmentPhase { get; set; } = 1;
}
