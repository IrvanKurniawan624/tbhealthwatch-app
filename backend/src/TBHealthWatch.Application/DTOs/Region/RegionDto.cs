namespace TBHealthWatch.Application.DTOs.Region;

public class RegionDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public string Kota { get; set; } = string.Empty;
}
