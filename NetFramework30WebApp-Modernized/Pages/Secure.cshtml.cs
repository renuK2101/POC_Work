using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.ApplicationInsights;
using System.Security.Claims;

[Authorize] // Require authentication
public class SecureModel : PageModel
{
    private readonly IConfiguration _configuration;
    private readonly TelemetryClient _telemetry;
    private readonly ILogger<SecureModel> _logger;

    public string UserName { get; set; } = string.Empty;
    public string AuthenticationType { get; set; } = string.Empty;
    public bool IsAuthenticated { get; set; }
    public List<string> UserRoles { get; set; } = new();
    public bool IsAuthorized { get; set; }

    public SecureModel(IConfiguration configuration, TelemetryClient telemetry, ILogger<SecureModel> logger)
    {
        _configuration = configuration;
        _telemetry = telemetry;
        _logger = logger;
    }

    public IActionResult OnGet()
    {
        try
        {
            // Check if user is authenticated
            if (!User.Identity?.IsAuthenticated == true)
            {
                _telemetry.TrackEvent("UnauthorizedAccessAttempt", new Dictionary<string, string>
                {
                    { "Page", "Secure" },
                    { "Reason", "NotAuthenticated" },
                    { "Timestamp", DateTime.UtcNow.ToString("o") }
                });

                return RedirectToPage("/Index");
            }

            // Get user information
            DisplayUserInformation();

            // Get user roles
            PopulateUserRoles();

            // Check authorization
            IsAuthorized = CheckAuthorization();

            // Log access
            _telemetry.TrackEvent("SecurePageAccess", new Dictionary<string, string>
            {
                { "UserName", UserName },
                { "IsAuthorized", IsAuthorized.ToString() },
                { "AuthType", AuthenticationType },
                { "Timestamp", DateTime.UtcNow.ToString("o") }
            });

            return Page();
        }
        catch (Exception ex)
        {
            _telemetry.TrackException(ex);
            _logger.LogError(ex, "Error processing Secure page request");
            IsAuthorized = false;
            return Page();
        }
    }

    private void DisplayUserInformation()
    {
        var principal = User as ClaimsPrincipal;

        // Get username from various claim types
        UserName = principal?.FindFirst(ClaimTypes.Name)?.Value
                ?? principal?.FindFirst("preferred_username")?.Value
                ?? principal?.FindFirst(ClaimTypes.Email)?.Value
                ?? User.Identity?.Name
                ?? "Unknown User";

        AuthenticationType = User.Identity?.AuthenticationType ?? "Azure AD";
        IsAuthenticated = User.Identity?.IsAuthenticated ?? false;
    }

    private void PopulateUserRoles()
    {
        UserRoles.Clear();
        var principal = User as ClaimsPrincipal;

        if (principal != null)
        {
            // Get roles from claims
            var roleClaims = principal.FindAll(ClaimTypes.Role);
            foreach (var role in roleClaims)
            {
                UserRoles.Add($"Role: {role.Value}");
            }

            // Get Azure AD groups
            var groupClaims = principal.FindAll("groups");
            foreach (var group in groupClaims)
            {
                UserRoles.Add($"Group: {group.Value}");
            }

            // Get directory roles
            var dirRoleClaims = principal.FindAll("roles");
            foreach (var dirRole in dirRoleClaims)
            {
                if (!UserRoles.Any(r => r.Contains(dirRole.Value)))
                {
                    UserRoles.Add($"Directory Role: {dirRole.Value}");
                }
            }

            if (!UserRoles.Any())
            {
                _telemetry.TrackEvent("NoRolesFound", new Dictionary<string, string>
                {
                    { "UserName", UserName },
                    { "ClaimsCount", principal.Claims.Count().ToString() }
                });
            }
        }
    }

    private bool CheckAuthorization()
    {
        try
        {
            // Get authorized roles from configuration
            var authorizedRoles = _configuration.GetSection("Authorization:Roles").Get<string[]>()
                               ?? new[] { "SecureAppUsers", "AppAdministrators" };

            // Check if user has any of the authorized roles
            foreach (var role in authorizedRoles)
            {
                if (User.IsInRole(role))
                {
                    _telemetry.TrackEvent("AuthorizationGranted", new Dictionary<string, string>
                    {
                        { "UserName", UserName },
                        { "Role", role },
                        { "Timestamp", DateTime.UtcNow.ToString("o") }
                    });

                    return true;
                }
            }

            _telemetry.TrackEvent("AuthorizationDenied", new Dictionary<string, string>
            {
                { "UserName", UserName },
                { "RequiredRoles", string.Join(", ", authorizedRoles) },
                { "Timestamp", DateTime.UtcNow.ToString("o") }
            });

            return false;
        }
        catch (Exception ex)
        {
            _telemetry.TrackException(ex);
            _logger.LogError(ex, "Error checking authorization");
            return false;
        }
    }
}
