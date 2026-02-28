using System.Web.Profile;

/// <summary>
/// Typed profile class for Web Application Project.
/// In Web Site projects, ASP.NET auto-generates this from Web.config profile definition.
/// In Web Application Projects, we must define it manually.
/// Matches the profile properties defined in Web.config.
/// </summary>
public class ProfileCommon : ProfileBase
{
    public static ProfileCommon GetProfile(string username)
    {
        return (ProfileCommon)ProfileBase.Create(username);
    }

    public new string UserName
    {
        get { return (string)GetPropertyValue("UserName"); }
        set { SetPropertyValue("UserName", value); }
    }

    public string Email
    {
        get { return (string)GetPropertyValue("Email"); }
        set { SetPropertyValue("Email", value); }
    }

    [SettingsAllowAnonymous(true)]
    public string FirstName
    {
        get { return (string)GetPropertyValue("FirstName"); }
        set { SetPropertyValue("FirstName", value); }
    }

    [SettingsAllowAnonymous(true)]
    public string LastName
    {
        get { return (string)GetPropertyValue("LastName"); }
        set { SetPropertyValue("LastName", value); }
    }

    public ProfileGroupJobSeeker JobSeeker
    {
        get { return (ProfileGroupJobSeeker)GetProfileGroup("JobSeeker"); }
    }

    public ProfileGroupEmployer Employer
    {
        get { return (ProfileGroupEmployer)GetProfileGroup("Employer"); }
    }
}

public class ProfileGroupJobSeeker : ProfileGroupBase
{
    public int ResumeID
    {
        get { return (int)GetPropertyValue("ResumeID"); }
        set { SetPropertyValue("ResumeID", value); }
    }
}

public class ProfileGroupEmployer : ProfileGroupBase
{
    public int CompanyID
    {
        get { return (int)GetPropertyValue("CompanyID"); }
        set { SetPropertyValue("CompanyID", value); }
    }
}
