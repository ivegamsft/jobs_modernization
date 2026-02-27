namespace JobSite.Core.DTOs;

/// <summary>
/// DTO for creating a new company
/// </summary>
public class CreateCompanyDto
{
    public string CompanyName { get; set; } = string.Empty;

    public string BriefProfile { get; set; } = string.Empty;

    public string Address1 { get; set; } = string.Empty;

    public string? Address2 { get; set; }

    public string City { get; set; } = string.Empty;

    public int StateId { get; set; }

    public int CountryId { get; set; }

    public string PostalCode { get; set; } = string.Empty;

    public string Phone { get; set; } = string.Empty;

    public string? Fax { get; set; }

    public string Email { get; set; } = string.Empty;

    public string? WebsiteUrl { get; set; }
}
