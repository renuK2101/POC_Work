# Azure Container Apps Deployment Script
# This script deploys the NetFramework30WebApp-Modernized application to Azure
# Generated: December 4, 2025

param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$true)]
    [string]$TenantId,
    
    [Parameter(Mandatory=$true)]
    [string]$ClientId,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "rg-netframework30-modernized",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "dev"
)

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "   Azure Container Apps Deployment" -ForegroundColor Cyan
Write-Host "   NetFramework30WebApp-Modernized (.NET 8)" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""

# Generate unique suffix for resource names
$suffix = -join ((97..122) | Get-Random -Count 6 | ForEach-Object {[char]$_})

# Resource names
$acrName = "acrnetframework30$suffix"
$logAnalyticsName = "log-netframework30-$Environment-$suffix"
$appInsightsName = "appi-netframework30-$Environment-$suffix"
$containerAppEnvName = "cae-netframework30-$Environment-$suffix"
$containerAppName = "ca-netframework30-$Environment-$suffix"
$managedIdentityName = "id-netframework30-containerapp-$suffix"
$imageName = "netframework30webapp-modernized"
$imageTag = "latest"

Write-Host "[Configuration]" -ForegroundColor Yellow
Write-Host "   Subscription ID: $SubscriptionId"
Write-Host "   Resource Group:  $ResourceGroupName"
Write-Host "   Location:        $Location"
Write-Host "   Environment:     $Environment"
Write-Host "   Suffix:          $suffix"
Write-Host ""

# Check if logged in to Azure
Write-Host "[1/10] Checking Azure login..." -ForegroundColor Cyan
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "[ERROR] Not logged in to Azure. Please run 'az login' first." -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Logged in as: $($account.user.name)" -ForegroundColor Green

# Set subscription
Write-Host "[2/10] Setting subscription..." -ForegroundColor Cyan
az account set --subscription $SubscriptionId
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to set subscription" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Subscription set" -ForegroundColor Green

# Create Resource Group
Write-Host ""
Write-Host "[3/10] Creating Resource Group..." -ForegroundColor Cyan
$currentDate = Get-Date -Format "yyyy-MM-dd"
az group create --name $ResourceGroupName --location $Location --tags "Created By=v-renukumari@microsoft.com" "Created On=$currentDate" "email-id=v-renukumari@microsoft.com" "Purpose=Migration Demo" "Customer=Internal" "Region=eastus" "Offering=Container Apps" Environment=$Environment Project=NetFramework30-Modernized ManagedBy=AzureCLI Framework=DotNet8 Platform=ContainerApps

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to create resource group" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Resource Group created: $ResourceGroupName" -ForegroundColor Green

# Create Log Analytics Workspace
Write-Host ""
Write-Host "[4/10] Creating Log Analytics Workspace..." -ForegroundColor Cyan
az monitor log-analytics workspace create --resource-group $ResourceGroupName --workspace-name $logAnalyticsName --location $Location

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to create Log Analytics workspace" -ForegroundColor Red
    exit 1
}

$workspaceId = az monitor log-analytics workspace show --resource-group $ResourceGroupName --workspace-name $logAnalyticsName --query customerId -o tsv
$workspaceKey = az monitor log-analytics workspace get-shared-keys --resource-group $ResourceGroupName --workspace-name $logAnalyticsName --query primarySharedKey -o tsv

Write-Host "[OK] Log Analytics Workspace created: $logAnalyticsName" -ForegroundColor Green

# Create Application Insights
Write-Host ""
Write-Host "[5/10] Creating Application Insights..." -ForegroundColor Cyan

# Install application-insights extension if not already installed
az extension add --name application-insights --only-show-errors 2>$null

az monitor app-insights component create --app $appInsightsName --location $Location --resource-group $ResourceGroupName --workspace $logAnalyticsName

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to create Application Insights" -ForegroundColor Red
    exit 1
}

$appInsightsKey = az monitor app-insights component show --app $appInsightsName --resource-group $ResourceGroupName --query connectionString -o tsv

Write-Host "[OK] Application Insights created: $appInsightsName" -ForegroundColor Green

# Create Azure Container Registry
Write-Host ""
Write-Host "[6/10] Creating Azure Container Registry..." -ForegroundColor Cyan
az acr create --resource-group $ResourceGroupName --name $acrName --sku Basic --admin-enabled true --location $Location

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to create Container Registry" -ForegroundColor Red
    exit 1
}

$acrLoginServer = az acr show --name $acrName --resource-group $ResourceGroupName --query loginServer -o tsv

Write-Host "[OK] Container Registry created: $acrName" -ForegroundColor Green
Write-Host "     Login Server: $acrLoginServer" -ForegroundColor Gray

# Build and Push Docker Image using ACR Build (cloud-based, doesn't require local Docker)
Write-Host ""
Write-Host "[7/10] Building and pushing Docker image using ACR Build..." -ForegroundColor Cyan
Write-Host "     This may take 5-10 minutes..." -ForegroundColor Gray

az acr build --registry $acrName --image ${imageName}:${imageTag} --file Dockerfile .

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to build and push Docker image" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Docker image built and pushed to ACR" -ForegroundColor Green

# Get ACR credentials for Container App authentication
Write-Host ""
Write-Host "[8/10] Getting ACR credentials..." -ForegroundColor Cyan

$acrUsername = az acr credential show --name $acrName --resource-group $ResourceGroupName --query username -o tsv
$acrPassword = az acr credential show --name $acrName --resource-group $ResourceGroupName --query passwords[0].value -o tsv

Write-Host "[OK] ACR credentials retrieved" -ForegroundColor Green

# Create Container Apps Environment
Write-Host ""
Write-Host "[9/10] Creating Container Apps Environment..." -ForegroundColor Cyan
az containerapp env create --name $containerAppEnvName --resource-group $ResourceGroupName --location $Location --logs-workspace-id $workspaceId --logs-workspace-key $workspaceKey

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to create Container Apps Environment" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Container Apps Environment created: $containerAppEnvName" -ForegroundColor Green

# Create Container App
Write-Host ""
Write-Host "[10/10] Creating Container App..." -ForegroundColor Cyan
az containerapp create --name $containerAppName --resource-group $ResourceGroupName --environment $containerAppEnvName --image "${acrLoginServer}/${imageName}:${imageTag}" --target-port 8080 --ingress external --registry-server $acrLoginServer --registry-username $acrUsername --registry-password $acrPassword --cpu 0.5 --memory 1.0Gi --min-replicas 1 --max-replicas 10 --env-vars "ASPNETCORE_ENVIRONMENT=$Environment" "AzureAd__TenantId=$TenantId" "AzureAd__ClientId=$ClientId" "AzureAd__Instance=https://login.microsoftonline.com/" "AzureAd__CallbackPath=/signin-oidc" "ApplicationInsights__ConnectionString=$appInsightsKey" "Authorization__Roles__0=SecureAppUsers" "Authorization__Roles__1=AppAdministrators"

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Failed to create Container App" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Container App created: $containerAppName" -ForegroundColor Green

# Get Application URL
$appUrl = az containerapp show --name $containerAppName --resource-group $ResourceGroupName --query properties.configuration.ingress.fqdn -o tsv

Write-Host ""
Write-Host "=================================================================" -ForegroundColor Green
Write-Host "   DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "[Deployment Summary]" -ForegroundColor Cyan
Write-Host "   Resource Group:         $ResourceGroupName"
Write-Host "   Location:               $Location"
Write-Host "   Container Registry:     $acrName"
Write-Host "   Container App:          $containerAppName"
Write-Host "   Application Insights:   $appInsightsName"
Write-Host ""
Write-Host "[Application URL]" -ForegroundColor Cyan
Write-Host "   https://$appUrl" -ForegroundColor Green
Write-Host ""
Write-Host "[Azure Portal]" -ForegroundColor Cyan
Write-Host "   https://portal.azure.com/#@$TenantId/resource/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName" -ForegroundColor Blue
Write-Host ""
Write-Host "[Next Steps]" -ForegroundColor Yellow
Write-Host "   1. Open the application URL in your browser"
Write-Host "   2. Test Azure AD authentication"
Write-Host "   3. Check Application Insights for telemetry"
Write-Host "   4. Monitor logs in Log Analytics workspace"
Write-Host ""
Write-Host "[TIP] Update your Azure AD App Registration redirect URI to:" -ForegroundColor Magenta
Write-Host "      https://$appUrl/signin-oidc"
Write-Host ""
