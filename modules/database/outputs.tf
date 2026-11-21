output "fqdn" {
  value = var.enable_database ? azurerm_postgresql_flexible_server.this[0].fqdn : null
}

output "admin_login" {
  value = var.admin_login
}

output "admin_password" {
  value     = var.enable_database ? random_password.admin[0].result : null
  sensitive = true
}

output "database_name" {
  value = var.database_name
}