output "plan_client_id" {
  value = azurerm_user_assigned_identity.plan.client_id
}

output "apply_client_id" {
  value = azurerm_user_assigned_identity.apply.client_id
}
