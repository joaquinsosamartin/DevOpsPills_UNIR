variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "staging"
}

variable "location" {
  description = "Azure region for this environment"
  type        = string
  default     = "westeurope"
}

variable "service_plan_sku" {
  description = "App Service Plan SKU for this environment"
  type        = string
  default     = "B1"
}
