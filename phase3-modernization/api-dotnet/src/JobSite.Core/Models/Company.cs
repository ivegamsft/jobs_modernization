namespace JobSite.Core.Models;

/// <summary>
/// Represents a company/employer in the system
/// </summary>
public class Company
{
    public int Id { get; set; }

    public string UserId { get; set; } = string.Empty;

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

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    // Navigation properties
    public virtual ICollection<JobPosting> JobPostings { get; set; } = [];
}
