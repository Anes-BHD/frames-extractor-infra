variable "subscription_id" { type = string }
variable "tfstate_resource_group_name" { type = string }
variable "tfstate_storage_account_name" { type = string }

variable "project" {
  type    = string
  default = "frames"
}

variable "owner" {
  type    = string
  default = "anesbhd"
}

variable "location" {
  type    = string
  default = "denmarkeast"
}

variable "github_owner" {
  type    = string
  default = "Anes-BHD"
}

variable "github_repo" {
  type    = string
  default = "frames-extractor-infra"
}

variable "environments" {
  description = "GitHub environments allowed to use the apply identity."
  type        = list(string)
  default     = ["dev", "test", "prod"]
}
