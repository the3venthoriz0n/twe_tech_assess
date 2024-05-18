param (
    [Parameter(Mandatory=$true)]
    [string]$ADAdminPassword,

    [Parameter(Mandatory=$true)]
    [string]$DomainController,

    [Parameter(Mandatory=$true)]
    [string]$ADForestName
)

# Add Data Disks and Initialize Disks
Initialize-Disk -Number 2 -PartitionStyle MBR -PassThru | `
    New-Partition -DriveLetter F -UseMaximumSize | `
    Format-Volume -FileSystem NTFS -NewFileSystemLabel "DataDisk"

# Install AD DS on the first VM and create a new forest if DomainController is "2731-tf-dc-0"
if ($DomainController -eq "2731-tf-dc-0") {
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    Import-Module ADDSDeployment
    Install-ADDSForest -DomainName $ADForestName `
        -CreateDnsDelegation:$true -DatabasePath "F:\Windows\NTDS" `
        -DomainMode "7" -DomainNetbiosName "TWE" -ForestMode "7" `
        -InstallDns:$true -LogPath "F:\Windows\NTDS" `
        -NoRebootOnCompletion:$true -SysvolPath "F:\Windows\SYSVOL" `
        -Force:$true -SafeModeAdministratorPassword (ConvertTo-SecureString $ADAdminPassword -AsPlainText -Force)
}
elseif ($DomainController -eq "2731-tf-dc-1") {
    # Install AD DS on the second DC and join the existing forest
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    Import-Module ADDSDeployment
    Install-ADDSDomainController -DomainName $ADForestName `
        -CreateDnsDelegation:$true `
        -Credential (New-Object System.Management.Automation.PSCredential("TWE\Administrator", (ConvertTo-SecureString $ADAdminPassword -AsPlainText -Force))) `
        -DatabasePath "F:\Windows\NTDS" `
        -LogPath "F:\Windows\NTDS" -SysvolPath "F:\Windows\SYSVOL" `
        -NoRebootOnCompletion:$true -Force:$true
}

# Set NTP Server
$ntpServer = "time.windows.com"

# Configure NTP Settings
w32tm /config /manualpeerlist:$ntpServer /syncfromflags:manual /reliable:YES /update

# Restart the Windows Time Service
Restart-Service w32time

# Set automatic timezone
Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate" -Name Start -Value 3

# Reboot vms
Restart-Computer -Force
