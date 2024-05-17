
param (
    [Parameter(Mandatory=$true)]
    [string]$AdminPassword

    [Parameter(Mandatory=$true)]
    [string]$Location

    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName

    [Parameter(Mandatory=$true)]
    [string]$DomainController

    [Parameter(Mandatory=$true)]
    [string]$ADForestName
)


# Variables
$Location="westus2"
$ResourceGroupName="Candidate-2731"
$DomainController1="2731-tf-dc-0"
$DomainController2="2731-tf-dc-1"
$ADForestName="twe-tech-assess.local"


#-----------------MANUAL-------------------




# Add Data Disks and Initialize Disks (login to each VM and run these scripts)
az vm run-command invoke --resource-group "Candidate-2731" --name "2731-tf-dc-0" --command-id RunPowerShellScript --scripts '
    Initialize-Disk -Number 2 -PartitionStyle MBR -PassThru | New-Partition -DriveLetter F -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "DataDisk"
'


# # Uninitialize disk, start over
# az vm run-command invoke --resource-group "Candidate-2731" --name "2731-tf-dc-0" --command-id RunPowerShellScript --scripts '
#     Clear-Disk 2 -RemoveData
# '

#TODO use env var $env:TF_VAR_admin_password

# Install AD DS on the first VM and create a new forest
az vm run-command invoke --resource-group "Candidate-2731" --name "2731-tf-dc-0" --command-id RunPowerShellScript --scripts '
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    Import-Module ADDSDeployment
    Install-ADDSForest -DomainName "twe-tech-assess.local" -CreateDnsDelegation:$false -DatabasePath "F:\Windows\NTDS" -DomainMode "7" -DomainNetbiosName "TWE" -ForestMode "7" -InstallDns:$true -LogPath "F:\Windows\NTDS" -NoRebootOnCompletion:$true -SysvolPath "F:\Windows\SYSVOL" -Force:$true -SafeModeAdministratorPassword (ConvertTo-SecureString "tempADPassword123!@#" -AsPlainText -Force)
'

# Install AD DS on the second VM and join the existing forest
az vm run-command invoke --resource-group "Candidate-2731" --name "2731-tf-dc-1" --command-id RunPowerShellScript --scripts '
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    Import-Module ADDSDeployment
    Install-ADDSDomainController -DomainName "twe-tech-assess.local" -CreateDnsDelegation:$false -Credential (New-Object System.Management.Automation.PSCredential("twe\Administrator", (ConvertTo-SecureString "tempADPassword123!@#" -AsPlainText -Force))) -DatabasePath "F:\Windows\NTDS" -LogPath "F:\Windows\NTDS" -SysvolPath "F:\Windows\SYSVOL" -NoRebootOnCompletion:$true -Force:$true
'



az vm run-command invoke --resource-group "Candidate-2731" --name "2731-tf-dc-0" --command-id RunPowerShellScript --scripts '

# Set NTP Server
$ntpServer = "time.windows.com"

# Configure NTP Settings
w32tm /config /manualpeerlist:$ntpServer /syncfromflags:manual /reliable:YES /update

# Restart the Windows Time Service
Restart-Service w32time

# Check NTP Configuration
#w32tm /query /status

# Set automatic timezone
Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate" -Name Start -Value 3 

'

az vm restart -g "Candidate-2731" -n "2731-tf-dc-0"