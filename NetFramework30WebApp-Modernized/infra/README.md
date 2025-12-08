# Azure Infrastructure - Terraform Configuration

This directory contains Terraform configuration for deploying the NetFramework30WebApp-Modernized application to Azure Container Apps.

## 📋 Prerequisites

### Required Tools
- [Terraform](https://www.terraform.io/downloads) >= 1.5.0
- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) >= 2.50.0
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (for building container images)

### Azure Requirements
- Azure subscription with appropriate permissions
- Azure AD App Registration with:
  - Tenant ID
  - Client ID
  - Configured redirect URIs: `https://your-app-url/signin-oidc`
  - App roles: `SecureAppUsers`, `AppAdministrators`

## 🚀 Quick Start

### 1. Install Terraform (if not installed)

```powershell
# Windows (using winget)
winget install Hashicorp.Terraform

# Verify installation
terraform version
```

### 2. Azure Login

```powershell
# Login to Azure
az login

# Set your subscription
az account set --subscription "<your-subscription-id>"

# Verify current subscription
az account show
```

### 3. Configure Variables

```powershell
# Copy example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
# IMPORTANT: Update azure_ad_tenant_id and azure_ad_client_id
```

### 4. Build and Push Container Image

Before deploying infrastructure, build and push your Docker image:

```powershell
# Navigate to project root
cd ..

# Build Docker image
docker build -t netframework30webapp-modernized:latest -f Dockerfile .

# After Terraform creates ACR, login and push:
# Get ACR login server from Terraform output
az acr login --name <acr-name>

# Tag image
docker tag netframework30webapp-modernized:latest <acr-login-server>/netframework30webapp-modernized:latest

# Push image
docker push <acr-login-server>/netframework30webapp-modernized:latest
```

### 5. Deploy Infrastructure

```powershell
# Navigate to infra directory
cd infra

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Preview changes
terraform plan

# Apply configuration (creates resources)
terraform apply -auto-approve
```

## 📁 File Structure

```
infra/
├── providers.tf              # Terraform and provider configuration
├── variables.tf              # Variable definitions
├── main.tf                   # Main resource definitions
├── outputs.tf                # Output values
├── terraform.tfvars.example  # Example variable values
├── terraform.tfvars          # Your actual values (DO NOT commit)
└── README.md                 # This file
```

## 🏗️ Resources Created

This Terraform configuration creates the following Azure resources:

| Resource Type | Name Pattern | Purpose |
|--------------|--------------|----------|
| **Resource Group** | `rg-netframework30-modernized` | Container for all resources |
| **Container Registry** | `acrnetframework30dev<suffix>` | Stores Docker images |
| **Container App Environment** | `cae-netframework30-dev-<suffix>` | Managed Kubernetes environment |
| **Container App** | `ca-netframework30-dev-<suffix>` | Application host |
| **Application Insights** | `appi-netframework30-dev-<suffix>` | Telemetry and monitoring |
| **Log Analytics Workspace** | `log-netframework30-dev-<suffix>` | Centralized logging |
| **Managed Identity** | `id-netframework30-containerapp-dev-<suffix>` | Secure resource access |

## 🔧 Configuration Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|----------|
| `azure_ad_tenant_id` | Azure AD Tenant ID | `12345678-1234-1234-1234-123456789012` |
| `azure_ad_client_id` | Azure AD Client ID (App Registration) | `87654321-4321-4321-4321-210987654321` |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `environment` | `dev` | Environment name |
| `location` | `eastus` | Azure region |
| `acr_sku` | `Basic` | Container Registry SKU |
| `container_app_min_replicas` | `1` | Minimum replicas |
| `container_app_max_replicas` | `10` | Maximum replicas |
| `container_cpu` | `0.5` | CPU cores |
| `container_memory` | `1Gi` | Memory allocation |

## 📤 Outputs

After deployment, Terraform provides these outputs:

```powershell
# View all outputs
terraform output

# View specific output
terraform output container_app_url

# View sensitive output
terraform output -raw container_registry_admin_password
```

### Key Outputs

- `container_app_url` - Application URL (https://...)
- `container_registry_login_server` - ACR login server
- `application_insights_connection_string` - App Insights connection
- `azure_portal_container_app_url` - Direct link to Azure Portal

## 🔐 Security Best Practices

### Implemented Security Features

✅ **Managed Identity** - Container App uses managed identity for ACR access  
✅ **No Anonymous Pull** - ACR anonymous pull disabled  
✅ **HTTPS Only** - Container App ingress enforces HTTPS  
✅ **Health Probes** - Liveness, readiness, and startup probes configured  
✅ **Azure AD Auth** - Application uses Azure AD OAuth2/OIDC  
✅ **Secrets Management** - Sensitive values not exposed in logs  

### Additional Recommendations

1. **Disable ACR Admin** - After initial deployment, disable admin account:
   ```powershell
   az acr update --name <acr-name> --admin-enabled false
   ```

2. **Use Key Vault** - For production, store secrets in Azure Key Vault

3. **Enable Defender** - Enable Azure Defender for Container Registry

4. **Network Restrictions** - Configure VNET integration for production

## 🔄 Deployment Workflow

### Initial Deployment

1. Create infrastructure: `terraform apply`
2. Build Docker image locally
3. Push to ACR: `docker push <acr>/<image>:tag`
4. Container App automatically pulls and deploys

### Updates

**Application Code Changes:**
```powershell
# Build new image
docker build -t <acr>/<image>:v2 .

# Push to ACR
docker push <acr>/<image>:v2

# Update Container App to use new image
az containerapp update \
  --name <app-name> \
  --resource-group <rg-name> \
  --image <acr>/<image>:v2
```

**Infrastructure Changes:**
```powershell
# Update terraform.tfvars or variables
terraform plan
terraform apply
```

## 🧹 Cleanup

To destroy all resources:

```powershell
# Preview what will be destroyed
terraform plan -destroy

# Destroy resources
terraform destroy -auto-approve
```

⚠️ **Warning**: This will delete all resources including:
- Container Registry and all images
- Application Insights telemetry data
- Log Analytics logs
- All application data

## 🐛 Troubleshooting

### Common Issues

**Issue: "Container image pull failed"**
```
Solution: Ensure image exists in ACR and managed identity has AcrPull role
Verify: az acr repository list --name <acr-name>
```

**Issue: "Authentication failed"**
```
Solution: Verify Azure AD configuration in terraform.tfvars
Check: Tenant ID and Client ID match App Registration
```

**Issue: "Health check failing"**
```
Solution: Verify /health endpoint responds on port 8080
Check application logs: az containerapp logs show --name <app-name> --resource-group <rg-name>
```

### View Container App Logs

```powershell
# Real-time logs
az containerapp logs show \
  --name <app-name> \
  --resource-group <rg-name> \
  --follow

# Specific revision logs
az containerapp revision list \
  --name <app-name> \
  --resource-group <rg-name>
```

### Check Application Insights

```powershell
# Open in Azure Portal
terraform output azure_portal_container_app_url

# Query logs in Log Analytics
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "ContainerAppConsoleLogs_CL | limit 100"
```

## 📚 Additional Resources

- [Azure Container Apps Documentation](https://learn.microsoft.com/azure/container-apps/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure AD App Registration](https://learn.microsoft.com/entra/identity-platform/quickstart-register-app)
- [Container Apps Best Practices](https://learn.microsoft.com/azure/container-apps/plans)

## 💡 Tips

- Use `terraform fmt` to format configuration files
- Use `terraform validate` before applying changes
- Enable verbose logging: `export TF_LOG=DEBUG`
- Store state remotely for team collaboration
- Use workspaces for multiple environments

---

**Generated**: December 4, 2025  
**Target**: Azure Container Apps  
**Framework**: .NET 8  
**IaC Tool**: Terraform
