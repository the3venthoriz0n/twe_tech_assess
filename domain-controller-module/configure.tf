resource "null_resource" "run_az_cli" {
  count = var.configure ? 2 : 0 # If configure is set to true, run 

  provisioner "local-exec" {
    command = <<EOT
      az vm run-command invoke \
        --resource-group "${var.resource_group_name}" \
        --name "${azurerm_windows_virtual_machine.dc[count.index].name}" \
        --command-id RunPowerShellScript \
        --scripts '@${path.module}/azcli_configure.ps1' \
        --parameters \
        "ADAdminPassword='${var.ad_admin_password}'" \
        "DomainController='${azurerm_windows_virtual_machine.dc[count.index].name}'" \
        "ADForestName='${var.domain_name}'"
    EOT
  }

  # Ensure the VMs are created before running the command
  depends_on = [
    azurerm_windows_virtual_machine.dc
  ]
}

