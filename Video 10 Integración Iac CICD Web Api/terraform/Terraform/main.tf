provider "azurerm" {
  features {}
  # use_cli = true #lanzar en local
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "unir" {
  name     = "unirdemos"
  location = "Spain Central"
}

resource "azurerm_log_analytics_workspace" "logAnalytics" {
  name                = "logAnalytics"
  location            = azurerm_resource_group.unir.location
  resource_group_name = azurerm_resource_group.unir.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "managedEnv20250828125507" {
  name                       = "managedEnv20250828125507"
  location                   = azurerm_resource_group.unir.location
  resource_group_name        = azurerm_resource_group.unir.name
  logs_destination           = "log-analytics"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logAnalytics.id

  tags = {
    Environment = "dev"
  }
}

resource "azurerm_container_registry" "jsmacr15" {
  name                = "jsmacr15"
  resource_group_name = azurerm_resource_group.unir.name
  location            = azurerm_resource_group.unir.location
  sku                 = "Basic"
  admin_enabled       = false

  tags = {
    Environment = "dev"
  }
}

# Grant the GitHub OIDC principal (current caller) AcrPush on the ACR so CI can push images
resource "azurerm_role_assignment" "acr_push_github" {
  scope                = azurerm_container_registry.jsmacr15.id
  role_definition_name = "AcrPush"
  principal_id         = data.azurerm_client_config.current.object_id
}

variable "image_tag" {
  description = "Container image tag to deploy"
  type        = string
  default     = "latest"
}

# Identity used by the Container App to pull images from ACR
resource "azurerm_user_assigned_identity" "acr_pull" {
  name                = "uami-acr-pull"
  location            = azurerm_resource_group.unir.location
  resource_group_name = azurerm_resource_group.unir.name
}

# Grant AcrPull to the identity on the ACR
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.jsmacr15.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.acr_pull.principal_id
}

# Azure Container App referencing the ACR image
resource "azurerm_container_app" "nvdproxy" {
  name                         = "nvdproxy"
  resource_group_name          = azurerm_resource_group.unir.name
  container_app_environment_id = azurerm_container_app_environment.managedEnv20250828125507.id
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.acr_pull.id]
  }

  # Use UAMI to authenticate to ACR when pulling images
  registry {
    server   = azurerm_container_registry.jsmacr15.login_server
    identity = azurerm_user_assigned_identity.acr_pull.id
  }

  ingress {
    external_enabled = true
    target_port      = 8080
    transport        = "auto"
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    container {
      name   = "nvd-proxy"
      image  = "${azurerm_container_registry.jsmacr15.login_server}/nvd-proxy:${var.image_tag}"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "ASPNETCORE_URLS"
        value = "http://+:8080"
      }
    }
  }

  tags = {
    Environment = "dev"
  }
}
