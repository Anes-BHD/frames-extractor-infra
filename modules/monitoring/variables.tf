variable "project" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }

variable "enable_monitoring" {
  type    = bool
  default = false
}

variable "vm_id" {
  type    = string
  default = null
}

variable "identity_id" { type = string }
variable "workspace_id" { type = string }
variable "alert_email" { type = string }
