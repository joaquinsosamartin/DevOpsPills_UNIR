variable "environment" {
  description = "Environment name (dev|staging/prod)"
  type        = string
}

variable "resource_group_name" {
  description = "Optional existing resource group name. If null, the module will create rg-<environment>."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "app_service_plan_id" {
  description = "Optional existing App Service plan ID"
  type        = string
  default     = null
}

variable "service_plan_sku" {
  description = "SKU for the service plan"
  type        = string
  default     = "F1"
}
