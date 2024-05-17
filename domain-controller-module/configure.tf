# TODO simplify
resource "null_resource" "run_az_cli" {
  count = 2

  provisioner "local-exec" {
    on_failure = continue
    command = <<EOT
      if [ "${var.configure}" == true ]; then
        powershell -File "${path.module}/azcli_configure.ps1"
      fi
    EOT

    # Ensure the VMs are created before running the command
  depends_on = [
    azurerm_windows_virtual_machine.dc
  ]
}
}