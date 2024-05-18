# Virtual Machine Extension for Domain Controller Setup
resource "azurerm_virtual_machine_extension" "dc_extension" {
  count                = 2
  name                 = "dc-extension-${count.index}"
  virtual_machine_id   = azurerm_windows_virtual_machine.dc[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = <<EOT


    # Set NTP Server
    $ntpServer = "time.windows.com"

    # Configure NTP Settings
    w32tm /config /manualpeerlist:$ntpServer /syncfromflags:manual /reliable:YES /update

    # Restart the Windows Time Service
    Restart-Service w32time

    # Set automatic timezone
    Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate" -Name Start -Value 3


    powershell -ExecutionPolicy Unrestricted `

    # Add Data Disks and Initialize Disks
    Initialize-Disk -Number 2 -PartitionStyle MBR -PassThru | `
      New-Partition -DriveLetter F -UseMaximumSize | `
      Format-Volume -FileSystem NTFS -NewFileSystemLabel "DataDisk"



    if ($count.index -eq 0){

        # Install AD DS on the first VM and create a new forest if DomainController is "2731-tf-dc-0"

        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
        Import-Module ADDSDeployment
        Install-ADDSForest `
        -DomainName ${var.domain_name} `
        -CreateDnsDelegation:${var.create_dns} -DatabasePath "F:\Windows\NTDS" `
        -DomainMode "7" -DomainNetbiosName "TWE" -ForestMode "7" `
        -InstallDns:$true -LogPath "F:\Windows\NTDS" `
        -NoRebootOnCompletion:$true -SysvolPath "F:\Windows\SYSVOL" `
        -Force:$true -SafeModeAdministratorPassword (ConvertTo-SecureString ${var.ad_admin_password} -AsPlainText -Force)

    }

    elseif($count.index -eq 1){

      # Install AD DS on the second DC and join the existing forest

      Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
      Import-Module ADDSDeployment
      Install-ADDSDomainController `
      -DomainName ${var.domain_name} `
      -CreateDnsDelegation:${var.create_dns} `
      -Credential (New-Object System.Management.Automation.PSCredential("TWE\Administrator", (ConvertTo-SecureString ${var.ad_admin_password} -AsPlainText -Force))) `
      -DatabasePath "F:\Windows\NTDS" `
      -LogPath "F:\Windows\NTDS" -SysvolPath "F:\Windows\SYSVOL" `
      -NoRebootOnCompletion:$true -Force:$true


    }
  
    # Reboot vms
    Restart-Computer -Force

    EOT
  })
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

