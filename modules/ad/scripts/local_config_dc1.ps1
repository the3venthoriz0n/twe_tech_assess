#$ErrorActionPreference = "Stop"

param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AdminUsername,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AdminPassword,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$DomainName
)



# Get the disk
$disk = Get-Disk -Number 2

# Check if the disk is already initialized by checking if it has any partitions
if ($disk.PartitionStyle -eq 'RAW') {
    Write-Host "Init disks..."
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


try  {

#TODO fix provisioning bug, add more logic

Write-Output "Installing AD DS and configuring the domain controller..."

Install-ADDSDomainController -DomainName $DomainName -CreateDnsDelegation:$false `
    -Credential (New-Object System.Management.Automation.PSCredential("$AdminUsername@$DomainName", `
    (ConvertTo-SecureString $AdminPassword -AsPlainText -Force))) `
    -DatabasePath "F:\Windows\NTDS" -LogPath "F:\Windows\NTDS" `
    -SysvolPath "F:\Windows\SYSVOL" -NoRebootOnCompletion:$true -Force:$true


}catch{
    Write-Output "Something went wrong installing AD..."
}


try {
    Write-Host "Setting time servers..."

    # Set NTP Server
    $ntpServer = "time.windows.com"

    # Configure NTP Settings
    w32tm /config /manualpeerlist:$ntpServer /syncfromflags:manual /reliable:YES /update

    # # Restart the Windows Time Service
    # Restart-Service w32time

    # Set automatic timezone
    # Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate" -Name Start -Value 3

    # Set PST
    Set-TimeZone -Id "Pacific Standard Time"



}catch{

    Write-Host "Something went wrong setting time servers..."

}



#FOR TESTING
$filePath = "C:\DONE.txt"

# Create an empty file and overwrite if it exists
try {
    $null | Out-File -FilePath $filePath -Force -Encoding ascii
    Write-Output "File created or overwritten."
} catch {
    Write-Output "Failed to create or overwrite file: $_"
}


# Reboot vms
Write-Host "Rebooting vm..."
Restart-Computer -Force

# Exit the script
Write-Host "Exiting..."
exit 0