#!/bin/bash

echo "Init disks..."

# Add Data Disks and Initialize Disks (login to each VM and run these scripts)
az vm run-command invoke --resource-group "Candidate-2731" --name "2731-tf-dc-0" --command-id RunPowerShellScript --scripts 'Initialize-Disk -Number 2 -PartitionStyle MBR -PassThru | New-Partition -DriveLetter F -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "DataDisk"'

# Add Data Disks and Initialize Disks (login to each VM and run these scripts)
az vm run-command invoke --resource-group "Candidate-2731" --name "2731-tf-dc-1" --command-id RunPowerShellScript --scripts 'Initialize-Disk -Number 2 -PartitionStyle MBR -PassThru | New-Partition -DriveLetter F -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "DataDisk"'

echo "Installing AD DS..."

# Install AD DS on the first VM and create a new forest
az vm run-command invoke --resource-group "Candidate-2731" --name "2731-tf-dc-0" --command-id RunPowerShellScript --scripts 'Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools; Import-Module ADDSDeployment; Install-ADDSForest -DomainName "twe-tech-assess.local" -CreateDnsDelegation $false -DatabasePath "F:\Windows\NTDS" -DomainMode 7 -DomainNetbiosName "TWE" -ForestMode 7 -InstallDns $true -LogPath "F:\Windows\NTDS" -NoRebootOnCompletion $false -SysvolPath "F:\Windows\SYSVOL" -Force $true -SafeModeAdministratorPassword (ConvertTo-SecureString "changeMe123!@#" -AsPlainText -Force)'

echo "Joining domain on second dc..."

# Install AD DS on the second VM and join the existing forest
az vm run-command invoke --resource-group "Candidate-2731" --name "2731-tf-dc-1" --command-id RunPowerShellScript --scripts 'Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools; Import-Module ADDSDeployment; Install-ADDSDomainController -DomainName "twe-tech-assess.local" -CreateDnsDelegation $false -Credential (New-Object System.Management.Automation.PSCredential("TWE\Administrator", (ConvertTo-SecureString "changeMe123!@#" -AsPlainText -Force))) -DatabasePath "F:\Windows\NTDS" -LogPath "F:\Windows\NTDS" -SysvolPath "F:\Windows\SYSVOL" -NoRebootOnCompletion $false -Force $true'

echo "Setting time servers..."

# Set NTP Server and configure NTP settings on the first VM
az vm run-command invoke --resource-group "Candidate-2731" --name "2731-tf-dc-0" --command-id RunPowerShellScript --scripts 'w32tm /config /manualpeerlist:time.windows.com /syncfromflags:manual /reliable:YES /update; Restart-Service w32time; Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate" -Name Start -Value 3'

# Set NTP Server and configure NTP settings on the second VM
az vm run-command invoke --resource-group "Candidate-2731" --name "2731-tf-dc-1" --command-id RunPowerShellScript --scripts 'w32tm /config /manualpeerlist:time.windows.com /syncfromflags:manual /reliable:YES /update; Restart-Service w32time; Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate" -Name Start -Value 3'

echo "Rebooting vms..."
# Reboot VMs
az vm restart --resource-group "Candidate-2731" --name "2731-tf-dc-0"
az vm restart --resource-group "Candidate-2731" --name "2731-tf-dc-1"

echo "Exiting..."


exit 0


# Debugging

# az vm run-command list --resource-group "Candidate-2731" --vm-name "2731-tf-dc-1" --query "[].{Name:name, Status:status}" --output table

# az vm run-command list --resource-group Candidate-2731 --vm-name "2731-tf-dc-1" --query "[].{Name:name, CommandId:id}" --output table


# az vm run-command show --resource-group "Candidate-2731" --vm-name "2731-tf-dc-1" --command-id <command-id>



