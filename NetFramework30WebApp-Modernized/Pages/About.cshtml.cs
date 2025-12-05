using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace NetFramework30WebApp_Modernized.Pages;

[AllowAnonymous] // Allow anonymous access to About page
public class AboutModel : PageModel
{
    private readonly ILogger<AboutModel> _logger;

    public AboutModel(ILogger<AboutModel> logger)
    {
        _logger = logger;
    }

    public void OnGet()
    {
        // Simple static page, no logic needed
    }
}

