using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace NetFramework30ASPNETWEB
{
    /// <summary>
    /// Default home page.
    /// Azure Migration: Updated to support Claims-based authentication while preserving business logic.
    /// Business Logic: Display current server time and user authentication information.
    /// </summary>
    public partial class Default : System.Web.UI.Page
    {
        /// <summary>
        /// Page Load event - displays server time and authentication info.
        /// Azure Migration: Enhanced to extract user info from claims (Azure AD).
        /// Business Logic: PRESERVED - same display logic for date/time and auth info.
        /// </summary>
        protected void Page_Load(object sender, EventArgs e)
        {
            // BUSINESS LOGIC PRESERVED: Set the current date and time on each page load
            string authInfo = "";
            
            // BUSINESS LOGIC PRESERVED: Add authentication details
            if (User != null && User.Identity != null)
            {
                string userName = User.Identity.Name;
                
                // Azure Migration: Try to get better display name from claims
                if (User is ClaimsPrincipal principal)
                {
                    // Try to get email claim for more user-friendly display
                    var emailClaim = principal.FindFirst(ClaimTypes.Email);
                    if (emailClaim != null && !string.IsNullOrEmpty(emailClaim.Value))
                    {
                        userName = emailClaim.Value;
                    }
                    else
                    {
                        // Try preferred_username (common in Azure AD tokens)
                        var preferredUsernameClaim = principal.FindFirst("preferred_username");
                        if (preferredUsernameClaim != null && !string.IsNullOrEmpty(preferredUsernameClaim.Value))
                        {
                            userName = preferredUsernameClaim.Value;
                        }
                    }
                }
                
                // BUSINESS LOGIC PRESERVED: Format authentication information
                authInfo = String.Format("User: {0} | Authenticated: {1} | Auth Type: {2}", 
                    userName ?? "Unknown", 
                    User.Identity.IsAuthenticated, 
                    User.Identity.AuthenticationType ?? "Azure AD");
            }
            else
            {
                authInfo = "User identity not available";
            }
            
            // BUSINESS LOGIC PRESERVED: Display server time and authentication info
            DateTimeLabel.Text = "Current server time: " + DateTime.Now.ToString("f") + " | " + authInfo;
        }
    }
}
