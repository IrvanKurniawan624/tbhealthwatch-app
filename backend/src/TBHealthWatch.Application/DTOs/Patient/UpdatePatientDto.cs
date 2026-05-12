using System.ComponentModel.DataAnnotations;

namespace TBHealthWatch.Application.DTOs.Patient;

public class UpdatePatientDto
{
    [Required, MaxLength(200)] public string FullName { get; set; } = string.Empty;
    public DateOnly? Dob { get; set; }
    public Guid? RegionId { get; set; }
    public string? Phone { get; set; }
    public string? Address { get; set; }
}
