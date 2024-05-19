# Install ADDS and configure dc0
resource "azurerm_virtual_machine_extension" "dc0_extension" {
  name                 = "configure-dc0"
  virtual_machine_id   = azurerm_windows_virtual_machine.dc[0].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  protected_settings = <<SETTINGS
  {
    "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.dc0_file.rendered)}')) | Out-File -filepath C:\\local_config_dc0.ps1\" && powershell -ExecutionPolicy Unrestricted -File C:\\local_config_dc0.ps1 -Force"
  }
  SETTINGS


  depends_on = [azurerm_windows_virtual_machine.dc]
}


data "template_file" "dc0_file" {
    template = "${file("${path.module}/scripts/local_config_dc0.ps1")}"
  #   vars = {
  #       Domain_DNSName          = "${var.Domain_DNSName}"
  #       Domain_NETBIOSName      = "${var.netbios_name}"
  #       SafeModeAdministratorPassword = "${var.SafeModeAdministratorPassword}"
  # }
}

# Install ADDS and configure dc1
resource "azurerm_virtual_machine_extension" "dc1_extension" {
  name                 = "configure-dc1"
  virtual_machine_id   = azurerm_windows_virtual_machine.dc[1].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  protected_settings = <<SETTINGS
  {
    "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.dc1_file.rendered)}')) | Out-File -filepath C:\\local_config_dc1.ps1\" && powershell -ExecutionPolicy Unrestricted -File C:\\local_config_dc1.ps1 -Force"
  }
  SETTINGS


  depends_on = [azurerm_windows_virtual_machine.dc, azurerm_virtual_machine_extension.dc0_extension]
}

data "template_file" "dc1_file" {
    template = "${file("${path.module}/scripts/local_config_dc1.ps1")}"
  #   vars = {
  #       Domain_DNSName          = "${var.Domain_DNSName}"
  #       Domain_NETBIOSName      = "${var.netbios_name}"
  #       SafeModeAdministratorPassword = "${var.SafeModeAdministratorPassword}"
  # }
}
