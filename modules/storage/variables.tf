variable "project" { type = string }
variable "environment" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tags" { type = map(string) }

variable "container_name" {
  description = "Private blob container for app data and ML artifacts."
  type        = string
  default     = "artifacts"
}
