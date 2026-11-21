variable "project" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }

variable "store_db_password" {
  description = "Whether to store the database admin password as a secret."
  type        = bool
  default     = false
}

variable "db_admin_password" {
  description = "Database admin password to store in the vault."
  type        = string
  default     = null
  sensitive   = true
}
