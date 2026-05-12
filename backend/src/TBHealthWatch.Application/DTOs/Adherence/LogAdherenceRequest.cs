using System.ComponentModel.DataAnnotations;

namespace TBHealthWatch.Application.DTOs.Adherence;

public class LogAdherenceRequest
{
    [Required] public DateOnly LogDate { get; set; }
    [Required] public string Status { get; set; } = string.Empty;
    public string? Notes { get; set; }
}
