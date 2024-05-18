

# Custom Script Extension for Domain Controller Setup
resource "azurerm_virtual_machine_extension" "dc_extension" {
  count                = 2
  name                 = "dc-extension-${count.index}"
  virtual_machine_id   = azurerm_windows_virtual_machine.dc[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell -ExecutionPolicy Unrestricted New-Item -Path '$env:USERPROFILE\Desktop\example.txt' -ItemType File"
    }
  SETTINGS

  # Ensure the VMs are created before running the command
  depends_on = [
    azurerm_windows_virtual_machine.dc
  ]
}




# # Virtual Machine Extension for Domain Controller Setup
# resource "azurerm_virtual_machine_extension" "dc_extension" {
#   count                = 2
#   name                 = "dc-extension-${count.index}"
#   virtual_machine_id   = element(azurerm_windows_virtual_machine.dc.*.id, count.index)
#   publisher            = "Microsoft.Compute"
#   type                 = "CustomScriptExtension"
#   type_handler_version = "1.10"

#   settings = jsonencode({
#     commandToExecute = <<EOT
#     # Promote the domain controller as the first in a new forest
#     # Execute only for the first instance (count.index == 0)

#     if ($count.index -eq 0) {
#         Install-ADDSForest `
#         -DomainName '${var.domain_name}' `
#         -InstallDns `
#         -SafeModeAdministratorPassword (ConvertTo-SecureString '${var.admin_password}' -AsPlainText -Force) `
#         -Force `
#         -Confirm:$false
#     }

#     if ($count.index -eq 1) {
#         Install-ADDSDomainController `
#         -DomainName "CONTOSO.com" `
#         -Credential (Get-Credential) `
#         -SafeModeAdministratorPassword (ConvertTo-SecureString '${var.admin_password}' -AsPlainText -Force) `
#         -Force `
#         -Confirm:$false `
#         -NoGlobalCatalog:$false `
#         -InstallDns:$true `
#         -NoRebootOnCompletion:$false `
#         -Path "F:\Windows\NTDS" `
#         -SysvolPath "F:\Windows\SYSVOL"
#     }

#       # Change the paths to point to the F: drive
#       # Perform this manually
#     EOT
#   })
# }



# resource "azurerm_virtual_machine_extension" "software" {
#   name                 = "install-software"
#   resource_group_name  = azurerm_resource_group.azrg.name
#   virtual_machine_id   = azurerm_virtual_machine.vm.id
#   publisher            = "Microsoft.Compute"
#   type                 = "CustomScriptExtension"
#   type_handler_version = "1.9"

#   protected_settings = <<SETTINGS
#   {
#      "commandToExecute": "powershell -encodedCommand ${textencodebase64(file("install.ps1"), "UTF-16LE")}"
#   }
#   SETTINGS
# }



# resource "null_resource" "run_az_cli" {
#   count = var.configure ? 2 : 0 # If configure is set to true, run 

#   provisioner "local-exec" {
#     command = <<EOT
#       az vm run-command invoke \
#         --resource-group "${var.resource_group_name}" \
#         --name "${azurerm_windows_virtual_machine.dc[count.index].name}" \
#         --command-id RunPowerShellScript \
#         --scripts '@${path.module}/azcli_configure.ps1' \
#         --parameters \
#         "ADAdminPassword='${var.ad_admin_password}'" \
#         "DomainController='${azurerm_windows_virtual_machine.dc[count.index].name}'" \
#         "ADForestName='${var.domain_name}'"
#     EOT
#   }

#   # Ensure the VMs are created before running the command
#   depends_on = [
#     azurerm_windows_virtual_machine.dc
#   ]
# }
