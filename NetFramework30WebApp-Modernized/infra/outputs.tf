# Terraform outputs for Azure Container Apps deployment

# Resource Group
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

# Container Registry
output "container_registry_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.main.name
}

output "container_registry_login_server" {
  description = "Login server URL for the container registry"
  value       = azurerm_container_registry.main.login_server
}

output "container_registry_admin_username" {
  description = "Admin username for container registry"
  value       = azurerm_container_registry.main.admin_username
  sensitive   = true
}

output "container_registry_admin_password" {
  description = "Admin password for container registry"
  value       = azurerm_container_registry.main.admin_password
  sensitive   = true
}

# Container App
output "container_app_name" {
  description = "Name of the Container App"
  value       = azurerm_container_app.main.name
}

output "container_app_fqdn" {
  description = "Fully qualified domain name of the Container App"
  value       = azurerm_container_app.main.ingress[0].fqdn
}

output "container_app_url" {
  description = "Application URL"
  value       = "https://${azurerm_container_app.main.ingress[0].fqdn}"
}

# Application Insights
output "application_insights_name" {
  description = "Name of Application Insights"
  value       = azurerm_application_insights.main.name
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

# Log Analytics
output "log_analytics_workspace_name" {
  description = "Name of Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

output "log_analytics_workspace_id" {
  description = "ID of Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

# Managed Identity
output "managed_identity_client_id" {
  description = "Client ID of the user-assigned managed identity"
  value       = azurerm_user_assigned_identity.containerapp.client_id
}

output "managed_identity_principal_id" {
  description = "Principal ID of the user-assigned managed identity"
  value       = azurerm_user_assigned_identity.containerapp.principal_id
}

# Azure Portal Links
output "azure_portal_resource_group_url" {
  description = "Azure Portal URL for the resource group"
  value       = "https://portal.azure.com/#@${var.azure_ad_tenant_id}/resource${azurerm_resource_group.main.id}"
}

output "azure_portal_container_app_url" {
  description = "Azure Portal URL for the Container App"
  value       = "https://portal.azure.com/#@${var.azure_ad_tenant_id}/resource${azurerm_container_app.main.id}"
}

# Deployment Summary
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    environment          = var.environment
    location             = var.location
    resource_group       = azurerm_resource_group.main.name
    container_registry   = azurerm_container_registry.main.name
    container_app        = azurerm_container_app.main.name
    application_url      = "https://${azurerm_container_app.main.ingress[0].fqdn}"
    application_insights = azurerm_application_insights.main.name
    log_analytics        = azurerm_log_analytics_workspace.main.name
  }
}
