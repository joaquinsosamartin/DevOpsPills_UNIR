variable "environment" {
  description = "Deployment environment name (e.g. dev, staging, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to create/use"
  type        = string
}

variable "location" {
  description = "Azure location for resources"
  type        = string
}

variable "app_service_plan_id" {
  description = "Optional existing App Service Plan ID. If not set, the module will create one."
  type        = string
  default     = null
}

variable "service_plan_sku" {
  description = "SKU name for the App Service Plan (e.g. F1, B1, S1, P1v3)"
  type        = string
  default     = "F1"
}
