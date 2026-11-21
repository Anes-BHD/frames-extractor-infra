output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "subnet_ids" {
  value = { for k, s in azurerm_subnet.this : k => s.id }
}

output "subnet_cidrs" {
  value = { for k, s in azurerm_subnet.this : k => s.address_prefixes[0] }
}

output "nat_public_ip" {
  value = var.enable_nat_gateway ? azurerm_public_ip.nat[0].ip_address : null
}
