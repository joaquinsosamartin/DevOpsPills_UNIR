variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for this environment"
  type        = string
  default     = "westeurope"
}

variable "service_plan_sku" {
  description = "App Service Plan SKU for this environment (e.g., F1, B1, S1, P1v3)"
  type        = string
  default     = "F1"
}

