
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}


data "azurerm_client_config" "current" {}



resource "azurerm_virtual_desktop_host_pool" "host_pool" {
  name                = "vdiHostPool"
  location            = var.location
  resource_group_name = var.rg_name
  type                = "Pooled"
  preferred_app_group_type = "Desktop"
  load_balancer_type  = "BreadthFirst"
  maximum_sessions_allowed   = 2
  friendly_name       = "Host Pool"
  description         = "VDI Host Pool"
  validate_environment = true
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "registration_info" {
  hostpool_id = azurerm_virtual_desktop_host_pool.host_pool.id
  expiration_date  = "2025-01-01T23:40:52Z" # a valid RFC3339Time expireation date of token
}


resource "azurerm_virtual_desktop_application_group" "app_group" {
  name                = "vdiAppGroup"
  resource_group_name = var.rg_name
  host_pool_id        = azurerm_virtual_desktop_host_pool.host_pool.id
  location            = var.location
  type                = "RemoteDesktop"
  friendly_name       = "App Group"
}


resource "azurerm_virtual_desktop_workspace" "workspace" {
  name                = "vdiWorkspace"
  resource_group_name = var.rg_name
  location            = var.location
  description         = "VDI Workspace"
  friendly_name       = "Workspace"
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "workspace_association" {
  workspace_id         = azurerm_virtual_desktop_workspace.workspace.id
  application_group_id = azurerm_virtual_desktop_application_group.app_group.id
}






