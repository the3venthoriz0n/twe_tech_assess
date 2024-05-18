
# Provider Configuration
provider "azurerm" {
  features {}
  skip_provider_registration = true
}


variable "admin_password" {
  description = "Local password for admin"
  type        = string
  sensitive   = true
}

variable "ad_admin_password" {
  description = "Password for AD Administrator"
  type        = string
  sensitive   = true
}

variable "resource_group_name" {
  description = "Existing resource group"
  type        = string
  default     = "Candidate-2731"
}

# numbers from resource group
locals {
  resource_group_number = regex("[0-9]+", var.resource_group_name)
}


module "domain_controllers" {
  source = "./domain-controller-module"

  # Input Variables

  resource_group_name     = "Candidate-2731" #existing resource group
  admin_password          = var.admin_password
  ad_admin_password       = var.ad_admin_password
  vm_name_prefix          = local.resource_group_number
  availability_set_name   = "${var.resource_group_name}-tf-avs"
  domain_name             = "twe-tech-assess.local"
  vnet_name               = "${var.resource_group_name}-tf-vnet"
  vnet_address_space      = ["10.2.0.0/16"]
  subnet_name             = "${var.resource_group_name}-tf-snet"
  subnet_address_prefixes = ["10.2.1.0/24"]
  nsg_name                = "${var.resource_group_name}-tf-nsg"
  configure               = false
  create_dns              = false
}
