using System.Web;

/// <summary>
/// Base page class providing typed Profile access for Web Application Project.
/// Pages that use typed Profile properties (JobSeeker, Employer, Email, etc.)
/// should inherit from this instead of System.Web.UI.Page.
/// </summary>
public class BasePage : System.Web.UI.Page
{
    public ProfileCommon Profile
    {
        get { return (ProfileCommon)HttpContext.Current.Profile; }
    }
}
