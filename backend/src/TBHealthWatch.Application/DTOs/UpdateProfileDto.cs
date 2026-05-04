using System.ComponentModel.DataAnnotations;

namespace TBHealthWatch.Application.DTOs;

public class UpdateProfileDto
{
    [Required, MaxLength(200)]
    public string FullName { get; set; } = string.Empty;
    public string? Specialization { get; set; }
    public string? FacilityName { get; set; }
    public string? FacilityRole { get; set; }
    public string? AssignmentLocation { get; set; }
    public Guid? RegionId { get; set; }
    public string? Phone { get; set; }
    public string? Address { get; set; }
    public string? AvatarUrl { get; set; }
}
