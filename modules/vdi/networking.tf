resource "azurerm_virtual_network" "vdi_vnet" {
  name                = "${var.rg_name}-vdi-vnet"
  address_space       = ["10.3.0.0/16"]
  location            = var.location
  resource_group_name = var.rg_name
}

resource "azurerm_subnet" "vdi_subnet" {
  name                 = "${var.rg_name}-vdi-snet"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vdi_vnet.name
  address_prefixes     = ["10.3.1.0/24"]
}

resource "azurerm_network_interface" "vdi_nic" {
  count               = 2
  name                = "vdi-nic-${count.index}"
  location            = var.location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vdi_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}
