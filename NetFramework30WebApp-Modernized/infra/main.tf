# Main Terraform configuration for Azure Container Apps deployment
# This file creates all required Azure resources for the modernized application

# Generate random suffix for unique resource names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Local variables for resource naming
locals {
  resource_suffix = random_string.suffix.result
  common_tags = merge(
    var.tags,
    {
      DeployedAt = timestamp()
    }
  )
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.project_name}-${var.environment}-${local.resource_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_analytics_retention_days
  tags                = local.common_tags
}

# Application Insights for telemetry
resource "azurerm_application_insights" "main" {
  name                = "appi-${var.project_name}-${var.environment}-${local.resource_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
  tags                = local.common_tags
}

# Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = "acr${var.project_name}${var.environment}${local.resource_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku
  admin_enabled       = true # Enable for initial deployment, use managed identity in production
  
  # Disable anonymous pull access (security best practice)
  anonymous_pull_enabled = false
  
  tags = local.common_tags
}

# Container Apps Environment
resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${var.project_name}-${var.environment}-${local.resource_suffix}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  tags                       = local.common_tags
}

# User Assigned Managed Identity for Container App
resource "azurerm_user_assigned_identity" "containerapp" {
  name                = "id-${var.project_name}-containerapp-${var.environment}-${local.resource_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

# Assign AcrPull role to managed identity
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.containerapp.principal_id
}

# Container App
resource "azurerm_container_app" "main" {
  name                         = "ca-${var.project_name}-${var.environment}-${local.resource_suffix}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  tags                         = local.common_tags

  # Managed Identity configuration
  identity {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.containerapp.id]
  }

  # Registry configuration
  registry {
    server   = azurerm_container_registry.main.login_server
    identity = azurerm_user_assigned_identity.containerapp.id
  }

  # Ingress configuration
  ingress {
    external_enabled = true
    target_port      = var.target_port
    transport        = "http"
    
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  # Template configuration
  template {
    min_replicas = var.container_app_min_replicas
    max_replicas = var.container_app_max_replicas

    container {
      name   = var.container_image_name
      image  = "${azurerm_container_registry.main.login_server}/${var.container_image_name}:${var.container_image_tag}"
      cpu    = var.container_cpu
      memory = var.container_memory

      # Environment variables for application configuration
      env {
        name  = "ASPNETCORE_ENVIRONMENT"
        value = var.environment == "prod" ? "Production" : "Development"
      }

      env {
        name  = "AzureAd__TenantId"
        value = var.azure_ad_tenant_id
      }

      env {
        name  = "AzureAd__ClientId"
        value = var.azure_ad_client_id
      }

      env {
        name  = "AzureAd__Instance"
        value = "https://login.microsoftonline.com/"
      }

      env {
        name  = "AzureAd__CallbackPath"
        value = "/signin-oidc"
      }

      env {
        name  = "ApplicationInsights__ConnectionString"
        value = azurerm_application_insights.main.connection_string
      }

      env {
        name  = "Authorization__Roles__0"
        value = "SecureAppUsers"
      }

      env {
        name  = "Authorization__Roles__1"
        value = "AppAdministrators"
      }

      # Liveness probe
      liveness_probe {
        transport = "HTTP"
        port      = var.target_port
        path      = "/health"
      }

      # Readiness probe
      readiness_probe {
        transport = "HTTP"
        port      = var.target_port
        path      = "/health"
      }

      # Startup probe
      startup_probe {
        transport = "HTTP"
        port      = var.target_port
        path      = "/health"
      }
    }
  }

  # Depend on role assignment to ensure permissions are set before deployment
  depends_on = [
    azurerm_role_assignment.acr_pull
  ]
}
