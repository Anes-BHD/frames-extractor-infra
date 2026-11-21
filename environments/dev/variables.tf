variable "subscription_id" { type = string }

variable "project" {
  type    = string
  default = "frames"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "owner" {
  type    = string
  default = "anesbhd"
}

variable "location" {
  type    = string
  default = "denmarkeast"
}
variable "enable_nat_gateway" {
  type    = bool
  default = false
}
variable "admin_ssh_public_key" {
  type        = string
  description = "SSH public key for the VM admin user (public, not a secret)."
}
variable "enable_app_gateway" {
  type    = bool
  default = false
}
variable "enable_database" {
  type    = bool
  default = false
}