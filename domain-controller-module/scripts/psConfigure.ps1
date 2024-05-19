# Check if the correct number of arguments is provided
if ($args.Count -ne 4) {
    Write-Host "Usage: $PSCommandPath <resourceGroup> <domainController> <domainName> <adAdminPassword>" 
    exit 1
}

# Access the arguments
$resourceGroup = $args[0]
$domainController = $args[1]
$domainName = $args[2]
$adAdminPassword = $args[3]

Write-Host "Init disks..."

# Add Data Disks and Initialize Disks (login to each VM and run these scripts)
Invoke-AzVMRunCommand -ResourceGroupName $resourceGroup -VMName $domainController -CommandId 'RunPowerShellScript' -ScriptBlock {
    Initialize-Disk -Number 2 -PartitionStyle MBR -PassThru | New-Partition -DriveLetter F -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "DataDisk"
}

if ($domainController -eq "2731-tf-dc-1") {
    Write-Host "Installing AD DS..."

    # Install AD DS on the first VM and create a new forest
    Invoke-AzVMRunCommand -ResourceGroupName $resourceGroup -VMName "2731-tf-dc-0" -CommandId 'RunPowerShellScript' -ScriptBlock {
        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
        Import-Module ADDSDeployment
        Install-ADDSForest -DomainName $using:domainName -CreateDnsDelegation:$false -DatabasePath "F:\Windows\NTDS" -DomainMode "7" -DomainNetbiosName "TWE" -ForestMode "7" -InstallDns:$true -LogPath "F:\Windows\NTDS" -NoRebootOnCompletion:$true -SysvolPath "F:\Windows\SYSVOL" -Force:$true -SafeModeAdministratorPassword (ConvertTo-SecureString $using:adAdminPassword -AsPlainText -Force)
    }

}

if ($domainController -eq "2731-tf-dc-1") {
    Write-Host "Joining domain on second dc..."

    # Install AD DS on the second VM and join the existing forest
    Invoke-AzVMRunCommand -ResourceGroupName $resourceGroup -VMName "2731-tf-dc-1" -CommandId 'RunPowerShellScript' -ScriptBlock {
        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
        Import-Module ADDSDeployment
        Install-ADDSDomainController -DomainName $using:domainName -CreateDnsDelegation:$false -Credential (New-Object System.Management.Automation.PSCredential("TWE\Administrator", (ConvertTo-SecureString $using:adAdminPassword -AsPlainText -Force))) -DatabasePath "F:\Windows\NTDS" -LogPath "F:\Windows\NTDS" -SysvolPath "F:\Windows\SYSVOL" -NoRebootOnCompletion:$true -Force:$true
    }

}

Write-Host "Setting time servers..."

Invoke-AzVMRunCommand -ResourceGroupName $resourceGroup -VMName $domainController -CommandId 'RunPowerShellScript' -ScriptBlock {
    # Set NTP Server
    $ntpServer = "time.windows.com"

    # Configure NTP Settings
    w32tm /config /manualpeerlist:$using:ntpServer /syncfromflags:manual /reliable:YES /update

    # Restart the Windows Time Service
    Restart-Service w32time

    # Set automatic timezone
    # Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate" -Name Start -Value 3

    # Set PST
    Set-TimeZone -Id "Pacific Standard Time"
}

Write-Host "Rebooting vms..."

# Reboot vms
Invoke-AzVMRestart -ResourceGroupName $resourceGroup -Name $domainController

# Exit the script
Write-Host "Exiting..."
