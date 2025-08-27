variable "backend_resource_group_name" {
  description = "Resource Group for Terraform remote state"
  type        = string
  default     = "tfstate-rg"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "westeurope"
}

variable "storage_account_name" {
  description = "Globally unique storage account name for the backend"
  type        = string
}

variable "container_name" {
  description = "Blob container name"
  type        = string
  default     = "tfstate"
}
