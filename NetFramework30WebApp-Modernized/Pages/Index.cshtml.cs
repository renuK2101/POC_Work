using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.RazorPages;
using System.Security.Claims;

namespace NetFramework30WebApp_Modernized.Pages;

[AllowAnonymous] // Allow anonymous access to home page
public class IndexModel : PageModel
{
    private readonly ILogger<IndexModel> _logger;

    public string CurrentDateTime { get; set; } = string.Empty;

    public IndexModel(ILogger<IndexModel> logger)
    {
        _logger = logger;
    }

    public void OnGet()
    {
        // Display current server time and authentication info
        string authInfo = "";

        if (User?.Identity != null)
        {
            string userName = User.Identity.Name ?? "Unknown";

            // Try to get better display name from claims
            if (User is ClaimsPrincipal principal)
            {
                var emailClaim = principal.FindFirst(ClaimTypes.Email);
                if (emailClaim != null && !string.IsNullOrEmpty(emailClaim.Value))
                {
                    userName = emailClaim.Value;
                }
                else
                {
                    var preferredUsernameClaim = principal.FindFirst("preferred_username");
                    if (preferredUsernameClaim != null && !string.IsNullOrEmpty(preferredUsernameClaim.Value))
                    {
                        userName = preferredUsernameClaim.Value;
                    }
                }
            }

            authInfo = $"User: {userName} | Authenticated: {User.Identity.IsAuthenticated} | Auth Type: {User.Identity.AuthenticationType ?? "Azure AD"}";
        }
        else
        {
            authInfo = "User identity not available";
        }

        CurrentDateTime = $"Current server time: {DateTime.Now:f} | {authInfo}";
    }
}
