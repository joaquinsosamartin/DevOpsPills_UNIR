# Root Terragrunt config for environment inheritance
# Run from each env folder (e.g., terragrunt run-all plan)

remote_state {
  backend = "azurerm"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateunir123456"
    container_name       = "tfstate"
    key                  = "${path_relative_to_include()}/terraform.tfstate"
    use_azuread_auth     = true
  }
}

