
# Local-exec provisioner to run a bash script
resource "null_resource" "local_exec_script" {
  count                = var.configure_via_local ? 2 : 0 # Change to 1 if running hardcode
  provisioner "local-exec" {
    # command = "bash ${path.module}/scripts/azcli_configure_hardcode.sh"
    command = "bash ${path.module}/scripts/azcli_configure.sh ${var.resource_group_name} ${azurerm_windows_virtual_machine.dc[count.index].name} ${var.domain_name} ${var.ad_admin_password}"

  }

  depends_on = [ azurerm_windows_virtual_machine.dc ]
}



# Run if configure set to true
resource "azurerm_virtual_machine_extension" "dc_all_config" {
  count                = var.configure ? 2 : 0
  name                 = "dc_all_config-${count.index}"
  virtual_machine_id   = azurerm_windows_virtual_machine.dc[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"


  settings = <<SETTINGS
    {
      "commandToExecute": "powershell -ExecutionPolicy Unrestricted -File test.ps1"
    }
SETTINGS

depends_on = [ azurerm_windows_virtual_machine.dc ]
}






