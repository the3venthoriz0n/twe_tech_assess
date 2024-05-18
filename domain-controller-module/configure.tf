resource "null_resource" "run_az_cli" {
  count = var.configure ? 2 : 0 # If configure is set to true, run 

  provisioner "local-exec" {
    command = <<EOT
      powershell -File "X:\domain-controller-module\azcli_configure_hardcode.ps1" `
        -ADAdminPassword "${var.ad_admin_password}" `
        -Location "${var.location}" `
        -ResourceGroupName "${var.resource_group_name}" `
        -DomainController1 "${azurerm_windows_virtual_machine.dc[0].name}" `
        -DomainController2 "${azurerm_windows_virtual_machine.dc[1].name}" `
        -DomainControllerAll "${azurerm_windows_virtual_machine.dc[count.index].name}" `
        -ADForestName "${var.domain_name}"
    EOT
  }

  # Ensure the VMs are created before running the command
  depends_on = [
    azurerm_windows_virtual_machine.dc
  ]
}

