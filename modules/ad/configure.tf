# Install ADDS and configure dc0
resource "azurerm_virtual_machine_extension" "dc0_extension" {
  count                = var.configure_via_local ? 1 :0
  name                 = "configure-dc0"
  virtual_machine_id   = azurerm_windows_virtual_machine.dc[0].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }

  protected_settings = <<SETTINGS
  {
    "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.dc0_file.rendered)}')) | Out-File -filepath C:\\local_config_dc0.ps1\" && powershell -ExecutionPolicy Unrestricted -File C:\\local_config_dc0.ps1 -DsrmPassword ${data.template_file.dc0_file.vars.dsrm_password} -DomainName ${data.template_file.dc0_file.vars.domain_name} -Force"
  }
  SETTINGS


  depends_on = [azurerm_windows_virtual_machine.dc,azurerm_virtual_machine_data_disk_attachment.dc_disk_attach]
}


data "template_file" "dc0_file" {
    template = "${file("${path.module}/scripts/local_config_dc0.ps1")}"
     vars = {
        dsrm_password = "${var.dsrm_password}"
        domain_name = "${var.domain_name}"
   }
}

# Install ADDS and configure dc1
resource "azurerm_virtual_machine_extension" "dc1_extension" {
  count                = var.configure_via_local ? 1 :0
  name                 = "configure-dc1"
  virtual_machine_id   = azurerm_windows_virtual_machine.dc[1].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  
  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }

  protected_settings = <<SETTINGS
  {
    "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.dc1_file.rendered)}')) | Out-File -filepath C:\\local_config_dc1.ps1\" && powershell -ExecutionPolicy Unrestricted -File C:\\local_config_dc1.ps1 -AdminUsername ${data.template_file.dc1_file.vars.admin_username} -AdminPassword ${data.template_file.dc1_file.vars.admin_password} -DomainName ${data.template_file.dc1_file.vars.domain_name} -Force"
  }
  SETTINGS


  depends_on = [azurerm_windows_virtual_machine.dc, azurerm_virtual_machine_extension.dc0_extension, azurerm_virtual_machine_data_disk_attachment.dc_disk_attach]
}

data "template_file" "dc1_file" {
    template = "${file("${path.module}/scripts/local_config_dc1.ps1")}"
     vars = {
        admin_username = "${var.admin_username}"
        admin_password = "${var.admin_password}"
        domain_name = "${var.domain_name}"

   }
}
