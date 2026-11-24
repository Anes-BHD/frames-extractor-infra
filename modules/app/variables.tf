variable "project" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }

variable "enable_app" {
  type    = bool
  default = false
}

variable "subnet_id" { type = string }
variable "app_asg_id" { type = string }
variable "admin_ssh_public_key" { type = string }

variable "zone" {
  type    = string
  default = "1"
}

variable "vm_size" {
  type    = string
  default = "Standard_B2as_v2"
}

variable "data_disk_size_gb" {
  type    = number
  default = 64
}

variable "identity_id" { type = string }
variable "identity_principal_id" { type = string }
variable "identity_client_id" { type = string }

variable "acr_id" { type = string }
variable "acr_login_server" { type = string }
variable "models_storage_account_id" { type = string }
variable "models_storage_account_name" { type = string }
variable "model_folder" { type = string }
variable "image_tag" { type = string }


variable "attach_to_gateway" {
  type    = bool
  default = false
}

variable "backend_pool_ids" {
  type    = list(string)
  default = []
}


variable "appinsights_connection_string" {
  description = "Application Insights connection string for the app telemetry (ingestion only)."
  type        = string
  default     = ""
  sensitive   = true
}
