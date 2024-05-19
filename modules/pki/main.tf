# https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-r2-and-2012/hh831348(v=ws.11)


terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Provider Configuration
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

data "azurerm_client_config" "current" {}



variable "rg_name" {
  description = "Existing resource group"
  type        = string
  default     = "Candidate-2731"
}

variable "location" {
  type        = string
  default     = "West US"
}

variable "admin_password" {
  description = "Password for Administrator"
  type        = string
  sensitive   = true
}

variable "admin_username" {
  type        = string
  default = "twe_admin"
}


# Virtual Network
resource "azurerm_virtual_network" "pki_vnet" {
  name                = "pki-vnet"
  resource_group_name = var.rg_name
  location            = var.location
  address_space       = ["10.4.0.0/16"]
}

# Subnet
resource "azurerm_subnet" "pki_subnet" {
  name                 = "pki-subnet"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.pki_vnet.name
  address_prefixes     = ["10.4.1.0/24"]
}

# PKI Tier 1 NIC
resource "azurerm_network_interface" "pki_tier1_nic" {
  name                = "pki-tier1-nic"
  resource_group_name = var.rg_name
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.pki_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# PKI Tier 2 NIC
resource "azurerm_network_interface" "pki_tier2_nic" {
  name                = "pki-tier2-nic"
  resource_group_name = var.rg_name
  location            = var.rg_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.pki_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}


# PKI Tier 1 VM
resource "azurerm_windows_virtual_machine" "pki_tier1_vm" {
  name                  = "pki-tier1-vm"
  resource_group_name   = var.rg_name
  location              = var.location
  size                  = "Standard_B2s"
  admin_username        = var.admin_username
  admin_password        = var.admin_password  # Define this variable as needed

  network_interface_ids = [azurerm_network_interface.pki_tier1_nic.id]

  os_disk {
    name              = "pki_tier1_osdisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  tags = {
    environment = "production"
  }
}



# PKI Tier 2 VM
resource "azurerm_windows_virtual_machine" "pki_tier2_vm" {
  name                  = "pki-tier2-vm"
  resource_group_name   = var.rg_name
  location              = var.location
  size                  = "Standard_B2s"
  admin_username        = var.admin_username
  admin_password        = var.admin_password  # Define this variable as needed

  network_interface_ids = [azurerm_network_interface.pki_tier2_nic.id]

  os_disk {
    name              = "pki_tier2_osdisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  tags = {
    environment = "pki"
  }
}


