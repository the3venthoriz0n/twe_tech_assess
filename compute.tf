
# Virtual Machines
resource "azurerm_windows_virtual_machine" "dc" {
  count                 = 2
  name                  = "dc-${count.index}"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = var.location
  size                  = "Standard_DS1_v2"
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [element(azurerm_network_interface.nic.*.id, count.index)]

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
}

# Custom Script Extension for Domain Controller Setup
resource "azurerm_virtual_machine_extension" "dc_extension" {
  count                = 2
  name                 = "dc-extension-${count.index}"
  virtual_machine_id   = element(azurerm_windows_virtual_machine.dc.*.id, count.index)
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell Add-WindowsFeature AD-Domain-Services; Install-ADDSForest -DomainName '${var.domain_name}' -InstallDns -SafeModeAdministratorPassword (ConvertTo-SecureString '${var.admin_password}' -AsPlainText -Force) -Force"
    }
  SETTINGS
}
