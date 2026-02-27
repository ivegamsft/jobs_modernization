using Microsoft.AspNetCore.Identity;

namespace JobSite.Infrastructure.Identity;

/// <summary>
/// Role definition for ASP.NET Core Identity
/// </summary>
public class AppRole : IdentityRole
{
    public string Description { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }
}
