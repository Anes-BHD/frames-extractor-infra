output "backend_pool_ids" {
  description = "Pool IDs for the scale sets (empty when the gateway is disabled)."
  value = [
    for g in azurerm_application_gateway.this :
    one([for p in g.backend_address_pool : p.id])
  ]
}

output "public_ip" {
  value = var.enable_app_gateway ? azurerm_public_ip.this[0].ip_address : null
}