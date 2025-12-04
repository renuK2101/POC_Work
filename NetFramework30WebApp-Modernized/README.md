# NetFramework30WebApp-Modernized

Modern .NET 8 Razor Pages application migrated from ASP.NET Framework 4.8 WebForms, designed for deployment to Azure Container Apps.

## 🚀 Overview

This application demonstrates a complete migration from legacy ASP.NET Framework WebForms to modern .NET 8 Razor Pages with Azure AD authentication and containerized deployment.

### Key Features
- ✅ .NET 8.0 (LTS) Razor Pages architecture
- ✅ Azure AD OAuth2/OIDC authentication
- ✅ Role-based authorization
- ✅ Application Insights telemetry
- ✅ Docker containerization
- ✅ Health checks for container orchestration
- ✅ Multi-stage optimized Docker builds

## 📋 Prerequisites

### Development
- .NET 8 SDK or later
- Docker Desktop (for containerization)
- Azure subscription (for deployment)
- Azure AD tenant (for authentication)

### Azure Resources (for deployment)
- Azure Container Registry (ACR)
- Azure Container Apps Environment
- Azure AD App Registration
- Application Insights

## 🔧 Configuration

### 1. Azure AD App Registration

Create an Azure AD app registration:

1. Go to [Azure Portal](https://portal.azure.com) → Azure Active Directory
2. Navigate to **App registrations** → **New registration**
3. Set redirect URI: `https://your-app-url/signin-oidc`
4. Copy **Tenant ID** and **Client ID**
5. Configure app roles:
   - `SecureAppUsers` - Access to secure pages
   - `AppAdministrators` - Admin access

### 2. appsettings.json

Update the configuration file:

```json
{
  "AzureAd": {
    "Instance": "https://login.microsoftonline.com/",
    "TenantId": "<YOUR_TENANT_ID>",
    "ClientId": "<YOUR_CLIENT_ID>",
    "CallbackPath": "/signin-oidc"
  },
  "ApplicationInsights": {
    "ConnectionString": "<YOUR_APP_INSIGHTS_CONNECTION_STRING>"
  }
}
```

## 🏗️ Build & Run

### Option 1: Build with .NET CLI

```powershell
# Build the application
.\build.ps1

# Or manually:
dotnet build --configuration Release
```

### Option 2: Run Locally

```powershell
# Run with dotnet
.\run-local.ps1

# Or manually:
dotnet run

# Application will start at http://localhost:5000
```

### Option 3: Build & Run with Docker

```powershell
# Build Docker image
.\docker-build.ps1

# Run container
.\run-local.ps1 -Docker

# Or manually:
docker build -t netframework30webapp-modernized:latest -f Dockerfile ..
docker run -p 5000:8080 netframework30webapp-modernized:latest
```

## 📦 Project Structure

```
NetFramework30WebApp-Modernized/
├── Pages/                      # Razor Pages
│   ├── Shared/
│   │   └── _Layout.cshtml     # Master layout
│   ├── Index.cshtml           # Home page
│   ├── About.cshtml           # About page
│   ├── Secure.cshtml          # Protected page (requires auth)
│   └── AccessDenied.cshtml    # Error page
├── wwwroot/                    # Static files
│   └── css/
│       └── site.css           # Styles
├── Program.cs                  # Application startup
├── appsettings.json           # Configuration
├── Dockerfile                 # Container build
├── build.ps1                  # Build script
├── docker-build.ps1           # Docker build script
└── run-local.ps1              # Run script
```

## 🔐 Authentication & Authorization

### Authentication Flow
1. User accesses protected page
2. Redirected to Azure AD login
3. After successful login, returned to application
4. Claims populated from Azure AD token

### Authorization Policies
- **SecurePageAccess**: Requires `SecureAppUsers` or `AppAdministrators` role
- Pages marked with `[AllowAnonymous]` are publicly accessible

### User Roles
Configure roles in Azure AD app registration and assign to users/groups.

## 🏥 Health Checks

Health endpoint available at: `/health`

Used by Azure Container Apps for:
- Liveness probes
- Readiness probes
- Startup probes

## 🐳 Docker Deployment

### Multi-Stage Build
The Dockerfile uses a multi-stage build for optimization:

1. **Build Stage**: Restores packages and builds application
2. **Publish Stage**: Creates optimized Release build
3. **Runtime Stage**: Minimal ASP.NET runtime image (~210 MB)

### Build Image
```powershell
docker build -t netframework30webapp-modernized:latest -f Dockerfile ..
```

### Run Container
```powershell
docker run -d \
  -p 8080:8080 \
  -e ASPNETCORE_ENVIRONMENT=Production \
  -e AzureAd__TenantId=<YOUR_TENANT_ID> \
  -e AzureAd__ClientId=<YOUR_CLIENT_ID> \
  -e ApplicationInsights__ConnectionString=<YOUR_CONNECTION_STRING> \
  netframework30webapp-modernized:latest
```

### Push to Azure Container Registry
```powershell
# Tag image
docker tag netframework30webapp-modernized:latest <your-registry>.azurecr.io/netframework30webapp-modernized:v1.0

# Login to ACR
az acr login --name <your-registry>

# Push image
docker push <your-registry>.azurecr.io/netframework30webapp-modernized:v1.0
```

## ☁️ Azure Container Apps Deployment

### Prerequisites
1. Azure Container Registry (ACR) with image
2. Azure Container Apps Environment
3. Application Insights instance

### Deploy with Azure CLI
```bash
az containerapp create \
  --name netframework30webapp-modernized \
  --resource-group <your-rg> \
  --environment <your-environment> \
  --image <your-registry>.azurecr.io/netframework30webapp-modernized:v1.0 \
  --target-port 8080 \
  --ingress external \
  --env-vars \
    AzureAd__TenantId=<YOUR_TENANT_ID> \
    AzureAd__ClientId=<YOUR_CLIENT_ID> \
    ApplicationInsights__ConnectionString=<YOUR_CONNECTION_STRING> \
  --cpu 0.5 \
  --memory 1.0Gi \
  --min-replicas 1 \
  --max-replicas 10
```

## 📊 Monitoring

### Application Insights
- **Telemetry**: Automatically tracked
- **Custom Events**: Logged on Secure page access
- **Dependencies**: HTTP calls, Azure AD auth
- **Exceptions**: Automatic exception tracking

### Metrics to Monitor
- Request rate and duration
- Failed requests
- Authentication failures
- Container health status
- CPU and memory usage

## 🔍 Troubleshooting

### Build Errors
```powershell
# Clean and rebuild
dotnet clean
dotnet restore
dotnet build
```

### Container Not Starting
```powershell
# Check container logs
docker logs <container-id>

# Verify health endpoint
curl http://localhost:8080/health
```

### Authentication Issues
1. Verify Azure AD app registration settings
2. Check redirect URI matches deployment URL
3. Ensure app roles are assigned to users
4. Validate `appsettings.json` configuration

## 📚 Additional Resources

- [ASP.NET Core Documentation](https://learn.microsoft.com/aspnet/core/)
- [Microsoft.Identity.Web](https://learn.microsoft.com/azure/active-directory/develop/microsoft-identity-web)
- [Azure Container Apps](https://learn.microsoft.com/azure/container-apps/)
- [.NET 8 What's New](https://learn.microsoft.com/dotnet/core/whats-new/dotnet-8)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

## 📝 Migration Documentation

See [MIGRATION-SUMMARY.md](MIGRATION-SUMMARY.md) for detailed migration notes from ASP.NET Framework 4.8 to .NET 8.

## 📄 License

See LICENSE file in the repository root.

## 🤝 Support

For issues or questions, please create an issue in the repository.

---

**Framework**: .NET 8.0 (LTS)  
**Target Platform**: Azure Container Apps  
**Authentication**: Azure AD (OAuth2/OIDC)  
**Monitoring**: Application Insights
