# terraform {
#   backend "azurerm" {
#     resource_group_name   = "<resource_group_name>"
#     storage_account_name  = "<storage_account_name>"
#     container_name        = "<container_name>"
#     key                   = "terraform.tfstate"
#   }
# }

#local backend due to RBAC limitations in test env

# Provider Configuration
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

#using local backend because of scope RBAC access limitations

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}


