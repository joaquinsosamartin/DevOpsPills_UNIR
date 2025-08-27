include "root" {
  path = find_in_parent_folders()
}

locals {
  environment      = "staging"
  location         = "westeurope"
  service_plan_sku = "B1"
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/web_app"
}

generate "providers.tf" {
  path      = "providers.tf"
  if_exists = "overwrite"
  contents  = <<EOF
provider "azurerm" {
  features {}
}
EOF
}

inputs = {
  environment         = local.environment
  location            = local.location
  service_plan_sku    = local.service_plan_sku
}
