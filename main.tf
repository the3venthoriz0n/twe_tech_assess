
# Provider Configuration
provider "azurerm" {
  features {}
  skip_provider_registration = true
}


variable "admin_password" {
  description = "Password for dc admin"
  type        = string
  sensitive   = true
}


# # Resource Group
# resource "azurerm_resource_group" "rg" {
#   name     = var.resource_group_name
#   location = var.location
# }

data "azurerm_resource_group" "rg" {
  name = "Candidate-2731"
}



module "domain_controllers" {
  source = "./domain-controller-module"

  # Input Variables
  admin_password      = var.admin_password
  resource_group_name = data.azurerm_resource_group.rg.name
}