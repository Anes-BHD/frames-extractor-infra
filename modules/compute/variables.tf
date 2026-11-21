variable "project" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }

variable "scale_sets" {
  description = "One scale set per zone: key => zone and subnet."
  type = map(object({
    zone      = string
    subnet_id = string
  }))
}

variable "app_asg_id" { type = string }

variable "vm_size" {
  type    = string
  default = "Standard_B1s"
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "admin_ssh_public_key" { type = string }

variable "min_capacity" {
  description = "Minimum instances per scale set."
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum instances per scale set."
  type        = number
  default     = 2
}

variable "health_port" {
  type    = number
  default = 80
}

variable "backend_pool_ids" {
  description = "Application Gateway backend pool IDs (empty until the load balancer exists)."
  type        = list(string)
  default     = []
}