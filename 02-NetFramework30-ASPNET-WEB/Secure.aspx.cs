using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Configuration;
using Microsoft.ApplicationInsights;
using System.Linq;

namespace NetFramework30ASPNETWEB
{
    /// <summary>
    /// Secure page that requires authenticated users with specific roles.
    /// Azure Migration: Updated to use Claims-based authentication instead of Windows Authentication.
    /// Business Logic: Authorization logic preserved - checks user roles/groups before showing content.
    /// </summary>
    public partial class Secure : System.Web.UI.Page
    {
        // Application Insights for monitoring and logging
        private readonly TelemetryClient telemetry = new TelemetryClient();
        
        /// <summary>
        /// Gets authorized roles from configuration (Web.config AppSettings).
        /// Azure Migration: Moved from hard-coded array to configuration for flexibility.
        /// Default roles: SecureAppUsers, AppAdministrators (Azure AD roles)
        /// </summary>
        private string[] GetAuthorizedRoles()
        {
            try
            {
                string rolesConfig = ConfigurationManager.AppSettings["AuthorizedRoles"];
                if (!string.IsNullOrEmpty(rolesConfig))
                {
                    return rolesConfig.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries)
                                     .Select(r => r.Trim())
                                     .ToArray();
                }
            }
            catch (Exception ex)
            {
                telemetry.TrackException(ex);
            }
            
            // Default roles if configuration is missing
            return new string[] { "SecureAppUsers", "AppAdministrators", "Authenticated Users" };
        }

        /// <summary>
        /// Page Load event - authenticates and authorizes user access.
        /// Azure Migration: Updated to use ClaimsPrincipal instead of WindowsIdentity.
        /// Business Logic: Same authorization flow - check auth, display info, authorize access.
        /// </summary>
        protected void Page_Load(object sender, EventArgs e)
        {
            try
            {
                // BUSINESS LOGIC PRESERVED: Check if the user is authenticated
                if (!User.Identity.IsAuthenticated)
                {
                    // Log unauthorized access attempt
                    telemetry.TrackEvent("UnauthorizedAccessAttempt", new Dictionary<string, string> {
                        { "Page", "Secure.aspx" },
                        { "Reason", "NotAuthenticated" },
                        { "Timestamp", DateTime.UtcNow.ToString("o") }
                    });
                    
                    // BUSINESS LOGIC PRESERVED: Redirect to home page if not authenticated
                    Response.Redirect("~/Default.aspx");
                    return;
                }

                // Azure Migration: Get ClaimsPrincipal instead of WindowsIdentity
                ClaimsPrincipal principal = User as ClaimsPrincipal;
                
                if (principal != null)
                {
                    // BUSINESS LOGIC PRESERVED: Display user information
                    DisplayUserInformation(principal);
                    
                    // BUSINESS LOGIC PRESERVED: Display group/role memberships
                    PopulateGroupsList(principal);
                    
                    // BUSINESS LOGIC PRESERVED: Check if user is authorized (same logic, different source)
                    bool isAuthorized = CheckAuthorization(principal);
                    
                    // BUSINESS LOGIC PRESERVED: Show appropriate content based on authorization
                    SecretPanel.Visible = isAuthorized;
                    UnauthorizedPanel.Visible = !isAuthorized;
                    
                    // BUSINESS LOGIC PRESERVED: Display authorization status
                    AuthorizationStatusLabel.Text = isAuthorized ? "Authorized" : "Not Authorized";
                    AuthorizationStatusLabel.ForeColor = isAuthorized ? 
                        System.Drawing.Color.Green : System.Drawing.Color.Red;

                    // Azure Migration: Log access for monitoring
                    telemetry.TrackEvent("SecurePageAccess", new Dictionary<string, string> {
                        { "UserName", UserNameLabel.Text },
                        { "IsAuthorized", isAuthorized.ToString() },
                        { "AuthType", AuthTypeLabel.Text },
                        { "Timestamp", DateTime.UtcNow.ToString("o") }
                    });
                }
                else
                {
                    // Handle unexpected case where ClaimsPrincipal is null
                    AuthorizationStatusLabel.Text = "Invalid Claims Principal";
                    AuthorizationStatusLabel.ForeColor = System.Drawing.Color.Red;
                    UnauthorizedPanel.Visible = true;
                    
                    telemetry.TrackEvent("SecurePageError", new Dictionary<string, string> {
                        { "Error", "InvalidClaimsPrincipal" },
                        { "Timestamp", DateTime.UtcNow.ToString("o") }
                    });
                }
            }
            catch (Exception ex)
            {
                // Azure Migration: Enhanced error handling with Application Insights
                telemetry.TrackException(ex);
                
                // Display friendly error message
                AuthorizationStatusLabel.Text = "Error processing authentication";
                AuthorizationStatusLabel.ForeColor = System.Drawing.Color.Red;
                UnauthorizedPanel.Visible = true;
            }
        }

        /// <summary>
        /// Displays user information from claims.
        /// Azure Migration: Extracts user info from claims instead of WindowsIdentity.
        /// Business Logic: Same display logic - show username, auth type, auth status.
        /// </summary>
        private void DisplayUserInformation(ClaimsPrincipal principal)
        {
            // Try to get the best username claim available
            string userName = principal.FindFirst(ClaimTypes.Name)?.Value 
                           ?? principal.FindFirst("preferred_username")?.Value 
                           ?? principal.FindFirst(ClaimTypes.Email)?.Value
                           ?? User.Identity.Name 
                           ?? "Unknown User";
            
            UserNameLabel.Text = userName;
            AuthTypeLabel.Text = User.Identity.AuthenticationType ?? "Azure AD";
            IsAuthenticatedLabel.Text = User.Identity.IsAuthenticated.ToString();
        }

        /// <summary>
        /// Populates the list of groups/roles the user belongs to.
        /// Azure Migration: Reads from Claims instead of Windows SIDs.
        /// Business Logic: Same purpose - display user's group memberships.
        /// </summary>
        private void PopulateGroupsList(ClaimsPrincipal principal)
        {
            GroupsList.Items.Clear();

            try
            {
                int itemCount = 0;
                
                // Azure Migration: Get roles from claims (Azure AD app roles)
                var roleClaims = principal.FindAll(ClaimTypes.Role);
                if (roleClaims != null && roleClaims.Any())
                {
                    foreach (var role in roleClaims)
                    {
                        GroupsList.Items.Add($"Role: {role.Value}");
                        itemCount++;
                    }
                }

                // Azure Migration: Get Azure AD groups (if configured in token)
                var groupClaims = principal.FindAll("groups");
                if (groupClaims != null && groupClaims.Any())
                {
                    foreach (var group in groupClaims)
                    {
                        GroupsList.Items.Add($"Group: {group.Value}");
                        itemCount++;
                    }
                }

                // Azure Migration: Alternative - check for directory roles
                var dirRoleClaims = principal.FindAll("roles");
                if (dirRoleClaims != null && dirRoleClaims.Any())
                {
                    foreach (var dirRole in dirRoleClaims)
                    {
                        if (!GroupsList.Items.Cast<ListItem>().Any(i => i.Text.Contains(dirRole.Value)))
                        {
                            GroupsList.Items.Add($"Directory Role: {dirRole.Value}");
                            itemCount++;
                        }
                    }
                }

                // BUSINESS LOGIC PRESERVED: Show message if no groups/roles found
                if (itemCount == 0)
                {
                    GroupsList.Items.Add("No roles or groups assigned");
                    
                    // Log for diagnostics
                    telemetry.TrackEvent("NoRolesFound", new Dictionary<string, string> {
                        { "UserName", UserNameLabel.Text },
                        { "ClaimsCount", principal.Claims.Count().ToString() }
                    });
                }
            }
            catch (Exception ex)
            {
                GroupsList.Items.Add($"Error retrieving roles: {ex.Message}");
                telemetry.TrackException(ex);
            }
        }

        /// <summary>
        /// Checks if user is authorized to view secure content.
        /// Azure Migration: Uses User.IsInRole() with Azure AD roles instead of Windows groups.
        /// Business Logic: PRESERVED - same authorization logic, checks if user has required role.
        /// </summary>
        private bool CheckAuthorization(ClaimsPrincipal principal)
        {
            try
            {
                // Get authorized roles from configuration
                string[] authorizedRoles = GetAuthorizedRoles();
                
                // BUSINESS LOGIC PRESERVED: Check if user has any of the authorized roles
                foreach (string role in authorizedRoles)
                {
                    if (User.IsInRole(role))
                    {
                        // Log successful authorization
                        telemetry.TrackEvent("AuthorizationGranted", new Dictionary<string, string> {
                            { "UserName", UserNameLabel.Text },
                            { "Role", role },
                            { "Timestamp", DateTime.UtcNow.ToString("o") }
                        });
                        
                        return true;
                    }
                }

                // Azure Migration: Optionally check for specific Azure AD group ObjectId
                // Uncomment and configure if using group ObjectIds instead of roles
                /*
                var groupClaims = principal.FindAll("groups");
                if (groupClaims != null)
                {
                    var authorizedGroupIds = new[] { "your-group-objectid-here" };
                    foreach (var groupClaim in groupClaims)
                    {
                        if (authorizedGroupIds.Contains(groupClaim.Value))
                        {
                            return true;
                        }
                    }
                }
                */

                // Log authorization denial
                telemetry.TrackEvent("AuthorizationDenied", new Dictionary<string, string> {
                    { "UserName", UserNameLabel.Text },
                    { "RequiredRoles", string.Join(", ", authorizedRoles) },
                    { "Timestamp", DateTime.UtcNow.ToString("o") }
                });

                // BUSINESS LOGIC PRESERVED: Return false if not in any authorized group
                return false;
            }
            catch (Exception ex)
            {
                // Log exception and deny access on error
                telemetry.TrackException(ex);
                return false;
            }
        }
    }
}
