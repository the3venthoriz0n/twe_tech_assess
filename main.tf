
# Provider Configuration
provider "azurerm" {
  features {}
  skip_provider_registration = true
}




module "domain_controllers" {
  source = "_Education/Terraform/twe_tech_assess/domain-controller-module"

  # Input Variables
  domain_name = var.domain_name
  
}
