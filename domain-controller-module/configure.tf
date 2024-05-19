
# Local-exec provisioner to run a bash script
resource "null_resource" "local_exec_script" {
  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/azcli_configure_hardcode.sh"
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






