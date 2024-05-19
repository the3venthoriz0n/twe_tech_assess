# Define provider
provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "pki_rg" {
  name     = "pki-resource-group"
  location = "East US"
}

# Virtual Network
resource "azurerm_virtual_network" "pki_vnet" {
  name                = "pki-vnet"
  resource_group_name = azurerm_resource_group.pki_rg.name
  location            = azurerm_resource_group.pki_rg.location
  address_space       = ["10.0.0.0/16"]
}

# Subnet
resource "azurerm_subnet" "pki_subnet" {
  name                 = "pki-subnet"
  resource_group_name  = azurerm_resource_group.pki_rg.name
  virtual_network_name = azurerm_virtual_network.pki_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# PKI Tier 1 VM
resource "azurerm_virtual_machine" "pki_tier1_vm" {
  name                  = "pki-tier1-vm"
  resource_group_name   = azurerm_resource_group.pki_rg.name
  location              = azurerm_resource_group.pki_rg.location
  vm_size               = "Standard_DS1_v2"
  network_interface_ids = [azurerm_network_interface.pki_tier1_nic.id]

  os_profile {
    computer_name  = "pki-tier1-vm"
    admin_username = "adminuser"
  }

  os_disk {
    caching              = "ReadWrite"
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

# PKI Tier 1 NIC
resource "azurerm_network_interface" "pki_tier1_nic" {
  name                = "pki-tier1-nic"
  resource_group_name = azurerm_resource_group.pki_rg.name
  location            = azurerm_resource_group.pki_rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.pki_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# PKI Tier 2 VM
resource "azurerm_virtual_machine" "pki_tier2_vm" {
  name                  = "pki-tier2-vm"
  resource_group_name   = azurerm_resource_group.pki_rg.name
  location              = azurerm_resource_group.pki_rg.location
  vm_size               = "Standard_DS1_v2"
  network_interface_ids = [azurerm_network_interface.pki_tier2_nic.id]

  os_profile {
    computer_name  = "pki-tier2-vm"
    admin_username = "adminuser"
  }

  os_disk {
    caching              = "ReadWrite"
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

# PKI Tier 2 NIC
resource "azurerm_network_interface" "pki_tier2_nic" {
  name                = "pki-tier2-nic"
  resource_group_name = azurerm_resource_group.pki_rg.name
  location            = azurerm_resource_group.pki_rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.pki_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}
