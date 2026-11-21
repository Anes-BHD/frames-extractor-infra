variable "project" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }

variable "vnet_id" {
  description = "VNet the private DNS zone is linked to."
  type        = string
}

variable "subnet_id" {
  description = "Delegated subnet for the server (db-a)."
  type        = string
}

variable "enable_database" {
  type    = bool
  default = false
}

variable "sku_name" {
  type    = string
  default = "B_Standard_B2s"
}

variable "storage_mb" {
  type    = number
  default = 32768
}

variable "admin_login" {
  type    = string
  default = "pgadmin"
}

variable "database_name" {
  type    = string
  default = "mlflow"
}