output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "acr_name" {
  value = azurerm_container_registry.this.name
}

output "acr_id" {
  value = azurerm_container_registry.this.id
}

output "acr_login_server" {
  value = azurerm_container_registry.this.login_server
}

output "models_storage_account_name" {
  value = azurerm_storage_account.models.name
}

output "models_storage_account_id" {
  value = azurerm_storage_account.models.id
}

output "models_container_name" {
  value = azurerm_storage_container.models.name
}
