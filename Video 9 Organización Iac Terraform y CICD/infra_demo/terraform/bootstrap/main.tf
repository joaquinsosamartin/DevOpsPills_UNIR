resource "azurerm_resource_group" "backend" {
  name     = var.backend_resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "backend" {
  name                            = var.storage_account_name
  resource_group_name             = azurerm_resource_group.backend.name
  location                        = azurerm_resource_group.backend.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }
}

resource "azurerm_storage_container" "state" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.backend.id
  container_access_type = "private"
}

output "backend_rg" {
  value = azurerm_resource_group.backend.name
}

output "backend_storage_account" {
  value = azurerm_storage_account.backend.name
}

output "backend_container" {
  value = azurerm_storage_container.state.name
}
