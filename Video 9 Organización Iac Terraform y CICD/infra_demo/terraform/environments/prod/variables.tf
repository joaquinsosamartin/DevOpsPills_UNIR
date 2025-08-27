variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region for this environment"
  type        = string
  default     = "westeurope"
}

variable "service_plan_sku" {
  description = "App Service Plan SKU for this environment"
  type        = string
  default     = "S1"
}
