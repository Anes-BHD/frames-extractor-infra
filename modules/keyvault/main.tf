data "azurerm_client_config" "current" {}

locals {
  prefix = "${var.project}-${var.environment}"
}

# Key Vault names are global and max 24 chars: "frames-dev-kv-" (14) + 6.
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Identity the app tier will use to read secrets (no passwords on the VMs).
resource "azurerm_user_assigned_identity" "this" {
  name                = "${local.prefix}-id"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_key_vault" "this" {
  name                = "${local.prefix}-kv-${random_string.suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = false # dev: lets destroy + recreate work cleanly
}

# Whoever runs Terraform may manage secrets.
resource "azurerm_role_assignment" "deployer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# The app identity may only read secrets.
resource "azurerm_role_assignment" "app_reader" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_key_vault_secret" "db_admin_password" {
  count        = var.store_db_password ? 1 : 0
  name         = "db-admin-password"
  value        = var.db_admin_password
  key_vault_id = azurerm_key_vault.this.id
  content_type = "text/plain"

  depends_on = [azurerm_role_assignment.deployer]
}
