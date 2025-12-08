# Variables for Azure Container Apps infrastructure
# Configure these values in terraform.tfvars or pass via command line

# General Configuration
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-netframework30-modernized"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "netframework30"
}

# Azure AD Configuration
variable "azure_ad_tenant_id" {
  description = "Azure AD Tenant ID"
  type        = string
  sensitive   = true
}

variable "azure_ad_client_id" {
  description = "Azure AD Client ID (from App Registration)"
  type        = string
  sensitive   = true
}

# Container Registry Configuration
variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  type        = string
  default     = "Basic"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "ACR SKU must be Basic, Standard, or Premium."
  }
}

# Container Apps Configuration
variable "container_app_min_replicas" {
  description = "Minimum number of container replicas"
  type        = number
  default     = 1
}

variable "container_app_max_replicas" {
  description = "Maximum number of container replicas"
  type        = number
  default     = 10
}

variable "container_cpu" {
  description = "CPU cores for container"
  type        = number
  default     = 0.5
}

variable "container_memory" {
  description = "Memory in Gi for container"
  type        = string
  default     = "1Gi"
}

variable "container_image_name" {
  description = "Container image name"
  type        = string
  default     = "netframework30webapp-modernized"
}

variable "container_image_tag" {
  description = "Container image tag"
  type        = string
  default     = "latest"
}

variable "target_port" {
  description = "Target port for the container app"
  type        = number
  default     = 8080
}

# Log Analytics Configuration
variable "log_analytics_retention_days" {
  description = "Log Analytics workspace retention in days"
  type        = number
  default     = 30
}

# Tags
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Development"
    Project     = "NetFramework30-Modernized"
    ManagedBy   = "Terraform"
    Framework   = "DotNet8"
    Platform    = "ContainerApps"
  }
}
