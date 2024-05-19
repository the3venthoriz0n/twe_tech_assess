#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <resourceGroup> <domainController> <domainName> <adAdminPassword>" 
    exit 1
fi

# Access the argument
resourceGroup=$1
domainController=$2
domainName=$3
adAdminPassword=$4


echo "Init disks..."

# Add Data Disks and Initialize Disks (login to each VM and run these scripts)
az vm run-command invoke --resource-group $resourceGroup --name $domainController --command-id RunPowerShellScript --scripts '
    powershell -ExecutionPolicy Unrestricted `
    Initialize-Disk -Number 2 -PartitionStyle MBR -PassThru | New-Partition -DriveLetter F -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "DataDisk"
'


# # Uninitialize disk, start over
# az vm run-command invoke --resource-group $resourceGroup --name $DomainControllerAll --command-id RunPowerShellScript --scripts '
#     Clear-Disk 2 -RemoveData
# '


if [ "$domainController" -eq "2731-tf-dc-1" ]; then
    echo "Installing AD DS..."

    # Install AD DS on the first VM and create a new forest
    az vm run-command invoke --resource-group $resourceGroup --name "2731-tf-dc-0" --command-id RunPowerShellScript --scripts '
        powershell -ExecutionPolicy Unrestricted `
        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools `
        Import-Module ADDSDeployment `
        Install-ADDSForest -DomainName $domainName -CreateDnsDelegation:$false -DatabasePath "F:\Windows\NTDS" -DomainMode "7" -DomainNetbiosName "TWE" -ForestMode "7" -InstallDns:$true -LogPath "F:\Windows\NTDS" -NoRebootOnCompletion:$true -SysvolPath "F:\Windows\SYSVOL" -Force:$true -SafeModeAdministratorPassword (ConvertTo-SecureString $adAdminPassword -AsPlainText -Force)
    '

    
fi


if [ "$domainController" -eq "2731-tf-dc-1" ]; then
    echo "Joining domain on second dc..."

    # Install AD DS on the second VM and join the existing forest
    az vm run-command invoke --resource-group $resourceGroup --name "2731-tf-dc-1" --command-id RunPowerShellScript --scripts '
        powershell -ExecutionPolicy Unrestricted `
        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools `
        Import-Module ADDSDeployment `
        Install-ADDSDomainController -DomainName $domainName -CreateDnsDelegation:$false -Credential (New-Object System.Management.Automation.PSCredential("TWE\Administrator", (ConvertTo-SecureString $adAdminPassword -AsPlainText -Force))) -DatabasePath "F:\Windows\NTDS" -LogPath "F:\Windows\NTDS" -SysvolPath "F:\Windows\SYSVOL" -NoRebootOnCompletion:$true -Force:$true
    '
    
fi

echo "Setting time servers..."

az vm run-command invoke --resource-group $resourceGroup --name $domainController --command-id RunPowerShellScript --scripts '
powershell -ExecutionPolicy Unrestricted `

# Set NTP Server
$ntpServer = "time.windows.com"

# Configure NTP Settings
w32tm /config /manualpeerlist:$ntpServer /syncfromflags:manual /reliable:YES /update

# Restart the Windows Time Service
Restart-Service w32time

# Check NTP Configuration
#w32tm /query /status

# Set automatic timezone
# Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate" -Name Start -Value 3

# Set PST
Set-TimeZone -Id "Pacific Standard Time"

'



echo "Rebooting vms..."
# Reboot vms
az vm restart -g $resourceGroup -n $domainController



# Exit the script
echo "Exiting..."
exit 0