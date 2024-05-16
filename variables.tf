# Define Variables
variable "resource_group_name" {
  type    = string
  default = "myResourceGroup"
}

variable "location" {
  type    = string
  default = "East US"
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "admin_password" {
  type    = string
  default = "ComplexPasswordHere!"
}

variable "domain_name" {
  type    = string
  default = "example.com"
}