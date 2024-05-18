

# Hardcode config for dc0
resource "azurerm_virtual_machine_extension" "dc0_extension" {
  name                 = "dc-extension-0"
  virtual_machine_id   = azurerm_windows_virtual_machine.dc[0].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = <<EOT
      powershell -ExecutionPolicy Unrestricted `
      Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools ;`
      Import-Module ADDSDeployment ;`
      Install-ADDSForest `
      -DomainName ${var.domain_name} `
      -CreateDnsDelegation:${var.create_dns} -DatabasePath "F:\\Windows\\NTDS" `
      -DomainMode "7" -DomainNetbiosName "TWE" -ForestMode "7" `
      -InstallDns:\$true -LogPath "F:\\Windows\\NTDS" `
      -NoRebootOnCompletion:\$true -SysvolPath "F:\\Windows\\SYSVOL" `
      -Force:\$true -SafeModeAdministratorPassword (ConvertTo-SecureString ${var.ad_admin_password} -AsPlainText -Force) ;`
      Restart-Computer -Force
EOT
  })

  depends_on = [ azurerm_windows_virtual_machine.dc ]
}

# Hardcode config for dc1
resource "azurerm_virtual_machine_extension" "dc1_extension" {
  name                 = "dc-extension-1"
  virtual_machine_id   = azurerm_windows_virtual_machine.dc[1].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = <<EOT
    powershell -ExecutionPolicy Unrestricted `
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools ;`
    Import-Module ADDSDeployment ;`
    Install-ADDSDomainController `
    -DomainName ${var.domain_name} `
    -CreateDnsDelegation:${var.create_dns} `
    -Credential (New-Object System.Management.Automation.PSCredential("TWE\\Administrator", (ConvertTo-SecureString ${var.ad_admin_password} -AsPlainText -Force))) `
    -DatabasePath "F:\\Windows\\NTDS" `
    -LogPath "F:\\Windows\\NTDS" -SysvolPath "F:\\Windows\\SYSVOL" `
    -NoRebootOnCompletion:\$true -Force:\$true ;`
    Restart-Computer -Force
EOT
  })

  depends_on = [ azurerm_windows_virtual_machine.dc ]
}


resource "azurerm_virtual_machine_extension" "dc_all_config" {
  count                = 2
  name                 = "dc_all_config-${count.index}"
  virtual_machine_id   = azurerm_windows_virtual_machine.dc[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"


  settings = jsonencode({
    commandToExecute = <<EOT
    powershell -ExecutionPolicy Unrestricted `Initialize-Disk -Number 2 -PartitionStyle MBR -PassThru | `
    New-Partition -DriveLetter F -UseMaximumSize | `
    Format-Volume -FileSystem NTFS -NewFileSystemLabel "DataDisk"; `
    w32tm /config /manualpeerlist:\${var.ntp_server} /syncfromflags:manual /reliable:YES /update ;`
    Restart-Service w32time ;`
    Set-ItemProperty -path "HKLM:\\SYSTEM\\CurrentControlSet\\Services\\tzautoupdate" -Name Start -Value 3
EOT
  })

  depends_on = [ azurerm_windows_virtual_machine.dc ]
}



