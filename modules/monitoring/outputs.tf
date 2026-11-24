output "data_collection_rule_id" {
  value = try(azurerm_monitor_data_collection_rule.this[0].id, null)
}
