terraform {
  required_version = ">= 1.6.0"
}

# Workspace-driven variables
variable "environment" { type = string }
variable "location" { type = string }
variable "service_plan_sku" {
  type    = string
  default = "F1"
}

# Per-workspace map values
locals {
  envs = {
    dev = {
      environment      = "dev"
      location         = "westeurope"
      service_plan_sku = "F1"
    }
    staging = {
      environment      = "staging"
      location         = "westeurope"
      service_plan_sku = "B1"
    }
    prod = {
      environment      = "prod"
      location         = "westeurope"
      service_plan_sku = "S1"
    }
  }

  selected = coalesce(
    try(local.envs[terraform.workspace], null),
    {
      environment      = var.environment
      location         = var.location
      service_plan_sku = var.service_plan_sku
    }
  )
}

# RG per workspace
resource "azurerm_resource_group" "this" {
  name     = "rg-${local.selected.environment}"
  location = local.selected.location
}

module "web_app" {
  source              = "./modules/web_app"
  environment         = local.selected.environment
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  service_plan_sku    = local.selected.service_plan_sku
}

output "app_url" {
  value = module.web_app.app_url
}
