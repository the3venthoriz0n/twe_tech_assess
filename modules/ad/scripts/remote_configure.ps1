$ErrorActionPreference = "Stop"


# Check if the correct number of arguments is provided
if ($args.Count -ne 5) {
    Write-Host "Usage: $PSCommandPath <domainController> <domainName> <adminUser> <adminPassword> <safeModeAdminPassword>" 
    exit 1
}

# Access the arguments
$domainController = $args[0]
$domainName = $args[1]
$adminUser = $args[2]
$adminPassword = $args[3]
$safeModeAdminPassword = $args[4]



Write-Host "Init disks..."

# Get the disk
$disk = Get-Disk -Number 2

# Check if the disk is already initialized by checking if it has any partitions
if ($disk.PartitionStyle -eq 'RAW') {
    # Disk is not initialized, proceed with initialization
    Initialize-Disk -Number 2 -PartitionStyle MBR -PassThru | New-Partition -DriveLetter F -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "DataDisk"
    Write-Output "Disk 2 has been initialized and formatted."
}
else {
    # Disk is already initialized
    Write-Output "Disk 2 is already initialized."
}


# Function to check if a Windows feature is installed
function Is-WindowsFeatureInstalled {
    param (
        [string]$FeatureName
    )
    $feature = Get-WindowsFeature -Name $FeatureName
    return $feature.Installed
}

# Function to check if a PowerShell module is available
function Is-ModuleAvailable {
    param (
        [string]$ModuleName
    )
    $module = Get-Module -ListAvailable -Name $ModuleName
    return $null -ne $module
}


# Check if the "AD-Domain-Services" feature is installed
if (-not (Is-WindowsFeatureInstalled -FeatureName "AD-Domain-Services")) {
    # Install the "AD-Domain-Services" feature
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    Write-Output "AD-Domain-Services feature installed."
}
else {
    Write-Output "AD-Domain-Services feature is already installed."
}

# Check if the "ADDSDeployment" module is available
if (-not (Is-ModuleAvailable -ModuleName "ADDSDeployment")) {
    # Import the "ADDSDeployment" module
    Import-Module ADDSDeployment
    Write-Output "ADDSDeployment module imported."
}
else {
    Write-Output "ADDSDeployment module is already available."
}





if ($domainController -eq "2731-tf-dc-0") {

    # Check if the forest already exists
    try {
        $forest = Get-ADForest
        Write-Output "The forest '$($forest.Name)' already exists."
    }
    catch {
        Write-Output "The forest does not exist. Creating a new forest..."
        # Create a new AD DS forest
        Install-ADDSForest -DomainName $domainName -CreateDnsDelegation:$false `
            -DatabasePath "F:\Windows\NTDS" -DomainMode "7" -DomainNetbiosName "TWE" `
            -ForestMode "7" -InstallDns:$true -LogPath "F:\Windows\NTDS" `
            -NoRebootOnCompletion:$true -SysvolPath "F:\Windows\SYSVOL" `
            -Force:$true -SafeModeAdministratorPassword (ConvertTo-SecureString $safeModeAdminPassword -AsPlainText -Force)
    }

}

if ($domainController -eq "2731-tf-dc-1") {

    
    Write-Output "Installing AD DS and configuring the domain controller..."


    Install-ADDSDomainController -DomainName $domainName -CreateDnsDelegation:$false `
        -Credential (New-Object System.Management.Automation.PSCredential("$adminUser@$domainName", `
            (ConvertTo-SecureString $adminPassword -AsPlainText -Force))) `
        -DatabasePath "F:\Windows\NTDS" -LogPath "F:\Windows\NTDS" `
        -SysvolPath "F:\Windows\SYSVOL" -NoRebootOnCompletion:$true -Force:$true

}




Write-Host "Setting time servers..."

# Set NTP Server
$ntpServer = "time.windows.com"

# Configure NTP Settings
w32tm /config /manualpeerlist:$ntpServer /syncfromflags:manual /reliable:YES /update

# Restart the Windows Time Service
Restart-Service w32time

# Set automatic timezone
# Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate" -Name Start -Value 3

# Set PST
Set-TimeZone -Id "Pacific Standard Time"



# Reboot vms
Write-Host "Rebooting vms..."
Restart-Computer -Force

# Exit the script
Write-Host "Exiting..."
exit 0