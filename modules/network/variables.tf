variable "project" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }

variable "address_space" {
  type    = list(string)
  default = ["10.20.0.0/16"]
}

variable "subnets" {
  description = "Map of subnet suffix to settings."
  type = map(object({
    cidr           = string
    private_subnet = optional(bool, false)
    delegation     = optional(string)
  }))
}
variable "enable_nat_gateway" {
  description = "Create a NAT Gateway for the private subnets (billed hourly)."
  type        = bool
  default     = false
}

variable "nat_subnets" {
  description = "Subnet suffixes that use the NAT Gateway for outbound traffic."
  type        = list(string)
  default     = ["app-a", "app-b"]
}
