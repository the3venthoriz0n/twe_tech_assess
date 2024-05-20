# Provider Configuration
provider "azurerm" {
  features {}
  skip_provider_registration = true
}


variable "admin_password" {
  description = "Local password for the administrator"
  type        = string
  sensitive   = true
}

variable "dsrm_password" {
  description = "Password for DSRM"
  type        = string
  sensitive   = true
}

variable "vdi_password" {
  description = "Password for vdi"
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


module "ad" {
  source = "./modules/ad"

  # Input Variables

  resource_group_name     = "Candidate-2731" #existing resource group
  admin_password          = var.admin_password
  dsrm_password           = var.dsrm_password
  vm_name_prefix          = local.resource_group_number
  availability_set_name   = "${var.resource_group_name}-tf-avs"
  domain_name             = "twe-tech-assess.local"
  vnet_name               = "${var.resource_group_name}-tf-vnet"
  vnet_address_space      = ["10.2.0.0/16"]
  subnet_name             = "${var.resource_group_name}-tf-snet"
  subnet_address_prefixes = ["10.2.1.0/24"]
  nsg_name                = "${var.resource_group_name}-tf-nsg"
  configure_via_local     = true  # locally on vm provisioner
  configure               = false # storage and other configuration
}


module "vdi" {
  count  = 0
  source = "./modules/vdi"

  # Input Variables

  vdi_password      = var.vdi_password
  ad_admin_password = var.admin_password

}

