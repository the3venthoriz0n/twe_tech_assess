# TODO simplify
resource "null_resource" "run_az_cli" {
  count = 2

  provisioner "local-exec" {
    command = <<EOT
      if [ ${var.configure_vm} == true ]; then

        # Run configure_all.ps1
        az vm run-command invoke \
          --resource-group ${var.resource_group_name} \
          --name ${azurerm_virtual_machine.dc[count.index].name} \
          --command-id RunPowerShellScript \
          --scripts "${path.module}/configure_all.ps1"
      fi
      
      if [ ${var.configure_ad} == true ]; then
        if [ ${count.index} -eq 0 ]; then
          script_path="${path.module}/configure_ad_primary.ps1"
        elif [ ${count.index} -eq 1 ]; then
          script_path="${path.module}/configure_ad_secondary.ps1"
        fi
      else
        script_path="${path.module}/configure_ad_false.ps1"
      fi

      # Run the chosen script
      az vm run-command invoke \
        --resource-group ${var.resource_group_name} \
        --name ${azurerm_virtual_machine.dc[count.index].name} \
        --command-id RunPowerShellScript \
        --scripts "${script_path} \
        --parameters '{
          "DomainName: "${var.domain_name}",
          "AdminPassword: "${var.admin_password}"
        }'
     fi
    EOT

    # Ensure the VM is created before running the command
    depends_on = [
      azurerm_virtual_machine.dc[*]
    ]
  }
}
