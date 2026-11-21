variable "project" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }

variable "subnet_id" {
  description = "Dedicated subnet for the gateway (public-a)."
  type        = string
}

variable "enable_app_gateway" {
  description = "Create the Application Gateway (billed hourly)."
  type        = bool
  default     = false
}

variable "backend_port" {
  type    = number
  default = 80
}

variable "capacity" {
  description = "Fixed number of gateway instances."
  type        = number
  default     = 1
}