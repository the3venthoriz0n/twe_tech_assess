
# # Local-exec provisioner to run a bash script
# resource "null_resource" "local_exec_script" {
#   count                = var.configure_via_local ? 2 : 0 # Change to 1 if running hardcode
#   provisioner "local-exec" {
#     # command = "bash ${path.module}/scripts/azcli_configure_hardcode.sh"
#     command = "bash ${path.module}/scripts/azcli_configure.sh ${var.resource_group_name} ${azurerm_windows_virtual_machine.dc[count.index].name} ${var.domain_name} ${var.ad_admin_password}"

#   }

#   depends_on = [ azurerm_windows_virtual_machine.dc ]
# }

resource "azurerm_virtual_machine_extension" "winrm" {
  count            = var.configure_via_local ? 2 : 0
  name                 = "winrm-extension-${count.index}"
  virtual_machine_id   = azurerm_windows_virtual_machine.dc[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = <<SETTINGS
  {
    "script": "powershell -ExecutionPolicy Unrestricted -Command \"winrm quickconfig -q; winrm set winrm/config/service '@{AllowUnencrypted=\"true\"}'; winrm set winrm/config/service/auth '@{Basic=\"true\"}'; \$cert = New-SelfSignedCertificate -DnsName 'localhost' -CertStoreLocation 'Cert:\\LocalMachine\\My'; \$thumbprint = \$cert.Thumbprint; winrm create winrm/config/Listener?Address=*+Transport=HTTPS '@{Hostname='*'; CertificateThumbprint='\$thumbprint'}'; New-NetFirewallRule -DisplayName 'WinRM over HTTPS' -Name 'WinRM-HTTPS' -Protocol TCP -LocalPort 5986 -Action Allow\""
  }
  SETTINGS

  depends_on = [ azurerm_windows_virtual_machine.dc ]
}

resource "null_resource" "upload_and_execute_script" {
  count            = var.configure_via_local ? 2 : 0

  # Use triggers to force the provisioners to run whenever the file changes
  triggers = {
    always_run = "${timestamp()}"
  }

  # Define connection details for the remote-exec provisioner
  connection {
    type        = "winrm"
    user        = var.admin_username
    password    = var.admin_password
    host        = azurerm_windows_virtual_machine.dc[count.index].private_ip_address
    port        = 5986
    timeout     = "10m"
  }

  # Use the file provisioner to upload the PowerShell script
  provisioner "file" {
    source      = "${path.module}/scripts/remote_configure.ps1"
    destination = "C:/temp/remote_configure.ps1"
  }

  # Use the remote-exec provisioner to execute the PowerShell script
  provisioner "remote-exec" {
    on_failure = fail
    inline = [
      "powershell.exe -ExecutionPolicy Bypass -File C:/temp/remote_configure.ps1 ${azurerm_windows_virtual_machine.dc[count.index].name} ${var.domain_name} ${var.admin_username} ${var.admin_password} ${var.ad_admin_password}"
    ]
  }

  depends_on = [ azurerm_virtual_machine_extension.winrm, azurerm_windows_virtual_machine.dc ]
}



