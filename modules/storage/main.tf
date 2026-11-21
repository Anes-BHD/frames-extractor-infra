
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_account" "this" {
  name                = "${var.project}${var.environment}st${random_string.suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }
}

resource "azurerm_storage_container" "this" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}
