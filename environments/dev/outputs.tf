output "app_gateway_public_ip" {
  value = module.load_balancer.public_ip
}

output "nat_public_ip" {
  value = module.network.nat_public_ip
}
output "db_fqdn" {
  value = module.database.fqdn
}

output "storage_account_name" {
  value = module.storage.storage_account_name
}

output "storage_container_name" {
  value = module.storage.container_name
}
