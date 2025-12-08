using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.RazorPages;

[AllowAnonymous] // Allow anonymous access to error page
public class AccessDeniedModel : PageModel
{
    private readonly ILogger<AccessDeniedModel> _logger;

    public AccessDeniedModel(ILogger<AccessDeniedModel> logger)
    {
        _logger = logger;
    }

    public void OnGet()
    {
        // Log access denied event
        _logger.LogWarning("Access denied page accessed by user: {User}", 
            User?.Identity?.Name ?? "Anonymous");
    }
}