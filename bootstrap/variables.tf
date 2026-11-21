variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."
}

variable "location" {
  type        = string
  description = "Azure region."
  default     = "denmarkeast"
}

variable "project" {
  type    = string
  default = "frames"
}

variable "owner" {
  type    = string
  default = "anesbhd"
}