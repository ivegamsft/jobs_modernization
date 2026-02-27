using Microsoft.AspNetCore.Identity;

namespace JobSite.Infrastructure.Identity;

/// <summary>
/// Extended user class for ASP.NET Core Identity
/// </summary>
public class AppUser : IdentityUser
{
    public string FirstName { get; set; } = string.Empty;

    public string LastName { get; set; } = string.Empty;

    public string? ProfilePictureUrl { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? LastLogin { get; set; }
}
