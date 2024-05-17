data "azurerm_virtual_network" "existing_vnet" {
  name                = "${var.resource_group_name}-vnet"
  resource_group_name = var.resource_group_name
}

data "azurerm_subnet" "existing_snet" {
  name                = "default"
  resource_group_name = var.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.existing_vnet.name
}


# Virtual Network
resource "azurerm_virtual_network" "dc_vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Subnet
resource "azurerm_subnet" "dc_subnet" {
  name                 = var.subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.dc_vnet.name
  address_prefixes     = var.subnet_address_prefixes

}


# # Config for existing nsg
# resource "azurerm_network_security_group" "existing_nsg" {
#   name                = "Candidate-2731-nsg"
#   location            = "West US 3"
#   resource_group_name = var.resource_group_name


#   security_rule {
#     name                       = "TF_AllowRDP"
#     priority                   = 1000
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "3389"
#     source_address_prefix      = "71.146.186.88"
#     destination_address_prefix = "*"
#   }

#   security_rule {
#     name                       = "TF_AllowPing"
#     priority                   = 1001
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Icmp"
#     source_port_range          = "*"
#     destination_port_range     = "*"
#     source_address_prefix      = "VirtualNetwork"
#     destination_address_prefix = "VirtualNetwork"
#   }

# }

# dc Network Security Group
resource "azurerm_network_security_group" "dc_nsg" {
  name                = var.nsg_name
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "TF_AllowRDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "TF_AllowPing"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }


}

# Network Interface
resource "azurerm_network_interface" "nic" {
  count               = 2
  name                = "${var.resource_group_name}-tf-nic-${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.dc_subnet.id
    private_ip_address_allocation = "Static" 
    # Use cidrhost built in function to calculate ip based on prefix, starting at .10
    private_ip_address            = "${cidrhost(var.subnet_address_prefixes[0], count.index + 10)}"
  }

}

# Create VNet Peering from "dc_vnet" to "Candidate-2731-vnet"
resource "azurerm_virtual_network_peering" "dc_vnet_to_existing" {
  name                         = "dc_vnet-to-candidate-peering"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.dc_vnet.name
  remote_virtual_network_id    = data.azurerm_virtual_network.existing_vnet.id
  allow_virtual_network_access = true # disallow internet access into "vnet"
}

# Create VNet Peering from "Candidate-2731-vnet" to "dc_vnet"
resource "azurerm_virtual_network_peering" "existing_to_dc_vnet" {
  name                         = "candidate-to-vnet-peering"
  resource_group_name          = var.resource_group_name
  virtual_network_name         = data.azurerm_virtual_network.existing_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.dc_vnet.id
  allow_virtual_network_access = true # allow communication between VNets
}

# NSG to subnet association
resource "azurerm_subnet_network_security_group_association" "sub_nsg_association" {
  subnet_id                 = azurerm_subnet.dc_subnet.id
  network_security_group_id = azurerm_network_security_group.dc_nsg.id
}

# NSG to nic association
resource "azurerm_network_interface_security_group_association" "nic_nsg_association" {
  count                     = 2
  network_interface_id      = azurerm_network_interface.nic[count.index].id
  network_security_group_id = azurerm_network_security_group.dc_nsg.id
}


# # Existing NSG to subnet association
# resource "azurerm_subnet_network_security_group_association" "exist_sub_nsg_association" {
#   subnet_id                 = data.azurerm_subnet.existing_snet.id
#   network_security_group_id = azurerm_network_security_group.existing_nsg.id
# }

# # NSG to nic association
# resource "azurerm_network_interface_security_group_association" "nic-nsg-association" {
#   count                     = 2
#   network_interface_id      = azurerm_network_interface.nic[count.index].id
#   network_security_group_id = azurerm_network_security_group.dc_nsg.id
# }