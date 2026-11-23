# Persistent resources shared by all environments (never destroyed per session):
# container registry for the app image, private storage for model weights.

data "azurerm_client_config" "current" {}

locals {
  tags = {
    Project     = var.project
    Environment = "shared"
    Owner       = var.owner
    ManagedBy   = "terraform"
  }
}

resource "azurerm_resource_group" "this" {
  name     = "${var.project}-shared-rg"
  location = var.location
  tags     = local.tags
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# ---------- Container registry ----------
resource "azurerm_container_registry" "this" {
  name                = "${var.project}shared${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "Basic"
  admin_enabled       = false
  tags                = local.tags
}

# ---------- Model storage (Azure AD auth only, no shared keys) ----------
resource "azurerm_storage_account" "models" {
  name                = "${var.project}models${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 30
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  tags = local.tags
}

resource "azurerm_storage_container" "models" {
  name                  = "models"
  storage_account_id    = azurerm_storage_account.models.id
  container_access_type = "private"
}

# ---------- Roles for the human operator (push images, upload models) ----------
resource "azurerm_role_assignment" "operator_acr_push" {
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPush"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "operator_models_contributor" {
  scope                = azurerm_storage_account.models.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}
