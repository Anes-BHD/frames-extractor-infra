variable "project" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }

variable "subnet_ids" {
  description = "Subnet suffix => subnet ID, from the network module."
  type        = map(string)
}

variable "subnet_cidrs" {
  description = "Subnet suffix => CIDR, from the network module."
  type        = map(string)
}

variable "app_ports" {
  description = "Ports the app tier serves to the load balancer."
  type        = list(string)
  default     = ["80", "8000"]
}