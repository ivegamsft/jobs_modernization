namespace JobSite.Core.Models;

/// <summary>
/// Represents a job posting created by an employer
/// </summary>
public class JobPosting
{
    public int Id { get; set; }

    public int CompanyId { get; set; }

    public string Title { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public string Department { get; set; } = string.Empty;

    public string JobCode { get; set; } = string.Empty;

    public string ContactPerson { get; set; } = string.Empty;

    public string City { get; set; } = string.Empty;

    public int StateId { get; set; }

    public int CountryId { get; set; }

    public int EducationLevelId { get; set; }

    public int JobTypeId { get; set; }

    public decimal? MinimumSalary { get; set; }

    public decimal? MaximumSalary { get; set; }

    public DateTime PostedDate { get; set; }

    public string PostedBy { get; set; } = string.Empty;

    public bool IsActive { get; set; } = true;

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    // Navigation properties
    public virtual Company Company { get; set; } = null!;
}
