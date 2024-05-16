
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


module "domain_controllers" {
  source = "./domain-controller-module"

  # Input Variables
  
  resource_group_name = "Candidate-2731" #existing resource group
  admin_password      = var.admin_password
  availability_set_name = "${module.domain_controllers.resource_group_name}-tf-avs"
  domain_name = "twe-tech-assess.local"
  vnet_name = "${module.domain_controllers.resource_group_name}-tf-vnet"
  vnet_address_space = ["10.2.0.0/16"]
  subnet_name = "${module.domain_controllers.resource_group_name}-tf-snet"
  subnet_address_prefixes = ["10.2.1.0/24"]
  nsg_name = "${module.domain_controllers.resource_group_name}-tf-nsg"

}