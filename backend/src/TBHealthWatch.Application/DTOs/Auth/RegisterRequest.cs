using System.ComponentModel.DataAnnotations;

namespace TBHealthWatch.Application.DTOs.Auth;

public class RegisterRequest
{
    [Required, EmailAddress] public string Email { get; set; } = string.Empty;
    [Required, MinLength(8)] public string Password { get; set; } = string.Empty;
    [Required, MaxLength(200)] public string FullName { get; set; } = string.Empty;
    public Guid? RegionId { get; set; }
    public string? Specialization { get; set; }
    public string? FacilityName { get; set; }
    public string? FacilityRole { get; set; }
    public string? AssignmentLocation { get; set; }
    public string? Phone { get; set; }
    public string? Address { get; set; }
}
