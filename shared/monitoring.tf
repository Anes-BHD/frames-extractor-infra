# Persistent monitoring backend: metric history and app telemetry survive every dev destroy.

resource "azurerm_log_analytics_workspace" "this" {
  name                = "${var.project}-shared-law"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  daily_quota_gb      = 0.5 # cost guard: ingestion stops for the day above this
  tags                = local.tags
}

resource "azurerm_application_insights" "this" {
  name                = "${var.project}-shared-appi"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  workspace_id        = azurerm_log_analytics_workspace.this.id
  application_type    = "web"
  tags                = local.tags
}

