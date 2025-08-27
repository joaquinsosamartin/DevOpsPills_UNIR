resource "azurerm_service_plan" "plan" {
  count               = var.app_service_plan_id == null ? 1 : 0
  name                = "plan-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.service_plan_sku
}

resource "azurerm_linux_web_app" "app" {
  name                = "webapi-${var.environment}-1515"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = var.app_service_plan_id != null ? var.app_service_plan_id : azurerm_service_plan.plan[0].id

  site_config {
    application_stack {
      dotnet_version = "8.0"
    }
    always_on = false
  }

  timeouts {
    read   = "5m"
    create = "10m"
    update = "10m"
  }
}
