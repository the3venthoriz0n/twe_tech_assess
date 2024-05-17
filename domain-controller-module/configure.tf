# Disk Initialization
resource "azurerm_virtual_machine_extension" "disk_initialization" {
  count                = 2
  name                 = "disk-initialization-${count.index}"
  virtual_machine_id   = element(azurerm_windows_virtual_machine.dc.*.id, count.index)
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = <<EOT
      # Get the list of available disks
      $Disks = Get-Disk

      # Initialize and format each data disk
      foreach ($Disk in $Disks) {
          if ($Disk.Size -gt 0 -and $Disk.Size -lt 128000000000) { # Filter disks by size (adjust as needed)
              $VolumeLabel = "DataDisk"
              Initialize-Disk -Number $Disk.Number -PartitionStyle MBR -Confirm:$false
              New-Partition -DiskNumber $Disk.Number -UseMaximumSize -AssignDriveLetter -DriveLetter F -Confirm:$false
              Format-Volume -DriveLetter F -FileSystem NTFS -NewFileSystemLabel $VolumeLabel -Confirm:$false
          }
      }
    EOT
  })
}

#TODO change to point to F: drive


# Define Azure Virtual Machine Extension for Disk Encryption
resource "azurerm_virtual_machine_extension" "disk_encryption_extension" {
  name                 = "diskEncryption"
  virtual_machine_id   = azurerm_windows_virtual_machine.example.id
  publisher            = "Microsoft.Azure.Security"
  type                 = "AzureDiskEncryption"
  type_handler_version = "2.2"

  settings = <<SETTINGS
    {
      "encryptionSettings": {
        "diskSettings": [
          {
            "diskEncryptionKeyVaultUrl": "${var.key_vault_url}",
            "keyEncryptionKeyUrl": "${var.key_encryption_key_url}",
            "keyVaultResourceId": "${azurerm_key_vault.example.id}"
          }
        ]
      }
    }
SETTINGS
}




# Virtual Machine Extension for Domain Controller Setup
resource "azurerm_virtual_machine_extension" "dc_extension" {
  count                = 2
  name                 = "dc-extension-${count.index}"
  virtual_machine_id   = element(azurerm_windows_virtual_machine.dc.*.id, count.index)
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    commandToExecute = <<EOT

    Add-WindowsFeature AD-Domain-Services

    # Set NTP Server
    $ntpServer = "time.windows.com"

    # Configure NTP Settings
    w32tm /config /manualpeerlist:$ntpServer /syncfromflags:manual /reliable:YES /update

    # Restart the Windows Time Service
    Restart-Service w32time

    # Check NTP Configuration
    #w32tm /query /status

    # Promote the domain controller as the first in a new forest
    # Execute only for the first instance (count.index == 0)

    if ($count.index -eq 0) {
        Install-ADDSForest `
        -DomainName '${var.domain_name}' `
        -InstallDns `
        -SafeModeAdministratorPassword (ConvertTo-SecureString '${var.admin_password}' -AsPlainText -Force) `
        -Force `
        -Confirm:$false
    }

    if ($count.index -eq 1) {
        Install-ADDSDomainController `
        -DomainName "CONTOSO.com" `
        -Credential (Get-Credential) `
        -SafeModeAdministratorPassword (ConvertTo-SecureString '${var.admin_password}' -AsPlainText -Force) `
        -Force `
        -Confirm:$false `
        -NoGlobalCatalog:$false `
        -InstallDns:$true `
        -NoRebootOnCompletion:$false `
        -Path "F:\Windows\NTDS" `
        -SysvolPath "F:\Windows\SYSVOL"
    }

      # Change the paths to point to the F: drive
      # Perform this manually





    EOT
  })
}


