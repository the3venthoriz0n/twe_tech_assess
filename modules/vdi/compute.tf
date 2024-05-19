resource "azurerm_windows_virtual_machine" "session_hosts" {
  count                 = 2
  name                  = "vdiSessionHost-${count.index}"
  resource_group_name   = var.rg_name
  location              = var.location
  size                  = "Standard_B2s"
  admin_username        = var.vdi_username
  admin_password        = var.vdi_password
  network_interface_ids = [azurerm_network_interface.vdi_nic[count.index].id]
  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "office-365"
    sku       = "win10-21h2-avd-m365"
    version   = "latest"
  }
  os_disk {
    name              = "vdi-osdisk-${count.index}"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Domain Join block
  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "vdi"
  }
}

resource "azurerm_virtual_machine_extension" "domain_join" {
  count                = 2
  name                 = "vdi-joindomain"
  virtual_machine_id   = azurerm_windows_virtual_machine.session_hosts[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"

  settings = <<-SETTINGS
    {
      "Name": "twe-tech-assess.local",
      "OUPath": "OU=Computers,DC=yourdomain,DC=com",
      "User": "TWE\\Administrator",
      "Restart": "true",
      "Options": "3"
    }
  SETTINGS

  protected_settings = <<-PROTECTED_SETTINGS
    {
      "Password": "${var.ad_admin_password}"
    }
  PROTECTED_SETTINGS

  depends_on = [ azurerm_windows_virtual_machine.session_hosts ]
}
