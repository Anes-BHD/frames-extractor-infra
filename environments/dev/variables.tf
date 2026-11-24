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

variable "enable_app" {
  type    = bool
  default = false
}

variable "shared_resource_group_name" {
  type    = string
  default = "frames-shared-rg"
}

variable "acr_name" {
  type    = string
  default = ""
}

variable "models_storage_account_name" {
  type    = string
  default = ""
}

variable "model_folder" {
  type    = string
  default = ""
}

variable "app_image_tag" {
  type    = string
  default = ""
}


variable "enable_nginx_tier" {
  description = "Demo nginx scale sets (not needed for the MLOps work)."
  type        = bool
  default     = false
}


variable "enable_monitoring" {
  type    = bool
  default = false
}

variable "alert_email" {
  type    = string
  default = ""
}
