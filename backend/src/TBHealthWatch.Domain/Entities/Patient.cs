namespace TBHealthWatch.Domain.Entities;

public class Patient
{
    public Guid Id { get; set; }
    public string? Nik { get; set; }
    public string FullName { get; set; } = string.Empty;
    public DateOnly? Dob { get; set; }
    public char? Gender { get; set; }
    public string? Phone { get; set; }
    public string? Address { get; set; }
    public Guid? RegionId { get; set; }
    public string? PhotoUrl { get; set; }
    public Guid? RegisteredByUserId { get; set; }
    public DateTime? RegisteredAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public DateTime? DeletedAt { get; set; }

    public Region? Region { get; set; }
    public ICollection<MedicationAdherence> MedicationAdherences { get; set; } = new List<MedicationAdherence>();
}
