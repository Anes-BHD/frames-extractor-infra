output "app_gateway_public_ip" {
  value = module.load_balancer.public_ip
}

output "nat_public_ip" {
  value = module.network.nat_public_ip
}
output "db_fqdn" {
  value = module.database.fqdn
}