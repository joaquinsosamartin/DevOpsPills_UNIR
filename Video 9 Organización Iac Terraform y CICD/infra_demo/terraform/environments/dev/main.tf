resource "azurerm_resource_group" "this" {
  name     = "rg-${var.environment}"
  location = var.location
}

module "web_app" {
  source              = "../../modules/web_app"
  environment         = var.environment
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  service_plan_sku    = var.service_plan_sku
}
