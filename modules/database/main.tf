locals {
  prefix = "${var.project}-${var.environment}"
}

resource "random_password" "admin" {
  count   = var.enable_database ? 1 : 0
  length  = 32
  special = false
}

resource "azurerm_private_dns_zone" "this" {
  count               = var.enable_database ? 1 : 0
  name                = "${local.prefix}.private.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  count                 = var.enable_database ? 1 : 0
  name                  = "${local.prefix}-pg-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this[0].name
  virtual_network_id    = var.vnet_id
  tags                  = var.tags
}

resource "azurerm_postgresql_flexible_server" "this" {
  count               = var.enable_database ? 1 : 0
  name                = "${local.prefix}-pg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  version                       = "16"
  sku_name                      = var.sku_name
  storage_mb                    = var.storage_mb
  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  public_network_access_enabled = false

  delegated_subnet_id = var.subnet_id
  private_dns_zone_id = azurerm_private_dns_zone.this[0].id

  administrator_login    = var.admin_login
  administrator_password = random_password.admin[0].result

  depends_on = [azurerm_private_dns_zone_virtual_network_link.this]

  lifecycle {
    ignore_changes = [zone]
  }
}

resource "azurerm_postgresql_flexible_server_database" "this" {
  count     = var.enable_database ? 1 : 0
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.this[0].id
  charset   = "UTF8"
  collation = "en_US.utf8"
}