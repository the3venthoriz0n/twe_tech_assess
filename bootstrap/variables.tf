variable "resource_group_name" {
  type    = string
  default = "tfstate-rg"
}

variable "storage_account_name" {
  type    = string
  default = "tfstate"
}

variable "container_name" {
  type    = string
  default = "tfstate"
}

variable "location" {
  type    = string
  default = "West US"
}