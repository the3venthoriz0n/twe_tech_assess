# terraform {
#   backend "azurerm" {
#     resource_group_name   = "<resource_group_name>"
#     storage_account_name  = "<storage_account_name>"
#     container_name        = "<container_name>"
#     key                   = "terraform.tfstate"
#   }
# }

#local backend due to RBAC limitations in test env

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}
