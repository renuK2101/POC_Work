using Microsoft.AspNetCore.Authentication.OpenIdConnect;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.Identity.Web;
using Microsoft.Identity.Web.UI;

namespace NetFramework30WebApp_Modernized
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);

            // Configure forwarded headers for reverse proxy support (Azure Container Apps, App Gateway, etc.)
            builder.Services.Configure<ForwardedHeadersOptions>(options =>
            {
                options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
                options.KnownNetworks.Clear();
                options.KnownProxies.Clear();
            });

            // Add Azure AD authentication
            builder.Services.AddAuthentication(OpenIdConnectDefaults.AuthenticationScheme)
                .AddMicrosoftIdentityWebApp(builder.Configuration.GetSection("AzureAd"));

            // Add Application Insights telemetry
            builder.Services.AddApplicationInsightsTelemetry(options =>
            {
                options.ConnectionString = builder.Configuration["ApplicationInsights:ConnectionString"];
            });

            // Add health checks
            builder.Services.AddHealthChecks();

            // Add services to the container
            builder.Services.AddRazorPages()
                .AddMicrosoftIdentityUI(); // Add Microsoft Identity UI components

            // Add authorization policies
            builder.Services.AddAuthorization(options =>
            {
                // Require authenticated users by default
                options.FallbackPolicy = options.DefaultPolicy;
                
                // Define custom policy for Secure page
                options.AddPolicy("SecurePageAccess", policy =>
                {
                    policy.RequireAuthenticatedUser();
                    policy.RequireRole("SecureAppUsers", "AppAdministrators");
                });
            });

            var app = builder.Build();

            // Use forwarded headers middleware (must be early in pipeline)
            app.UseForwardedHeaders();

            // Configure the HTTP request pipeline
            if (!app.Environment.IsDevelopment())
            {
                app.UseExceptionHandler("/Error");
                app.UseHsts();
            }

            app.UseHttpsRedirection();
            app.UseStaticFiles();

            app.UseRouting();

            // Authentication & Authorization middleware (order matters!)
            app.UseAuthentication();
            app.UseAuthorization();

            // Map health check endpoint
            app.MapHealthChecks("/health");

            app.MapRazorPages();
            app.MapControllers(); // For Microsoft Identity UI controllers

            app.Run();
        }
    }
}
