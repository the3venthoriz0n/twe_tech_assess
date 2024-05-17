
param (
    [Parameter(Mandatory=$true)]
    [string]$ADAdminPassword

    [Parameter(Mandatory=$true)]
    [string]$Location

    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName

    [Parameter(Mandatory=$true)]
    [string]$DomainController1

    [Parameter(Mandatory=$true)]
    [string]$DomainController2
    
    [Parameter(Mandatory=$true)]
    [string]$DomainControllerAll

    [Parameter(Mandatory=$true)]
    [string]$ADForestName
)




# Add Data Disks and Initialize Disks (login to each VM and run these scripts)
az vm run-command invoke --resource-group $ResourceGroupName --name $DomainControllerAll --command-id RunPowerShellScript --scripts '
    Initialize-Disk -Number 2 -PartitionStyle MBR -PassThru | New-Partition -DriveLetter F -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "DataDisk"
'


# # Uninitialize disk, start over
# az vm run-command invoke --resource-group $ResourceGroupName --name $DomainControllerAll --command-id RunPowerShellScript --scripts '
#     Clear-Disk 2 -RemoveData
# '



# Install AD DS on the first VM and create a new forest
az vm run-command invoke --resource-group $ResourceGroupName --name $DomainController1 --command-id RunPowerShellScript --scripts '
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    Import-Module ADDSDeployment
    Install-ADDSForest -DomainName $ADForestName -CreateDnsDelegation:$true -DatabasePath "F:\Windows\NTDS" -DomainMode "7" -DomainNetbiosName "TWE" -ForestMode "7" -InstallDns:$true -LogPath "F:\Windows\NTDS" -NoRebootOnCompletion:$true -SysvolPath "F:\Windows\SYSVOL" -Force:$true -SafeModeAdministratorPassword (ConvertTo-SecureString $ADAdminPassword -AsPlainText -Force)
'

# Install AD DS on the second VM and join the existing forest
az vm run-command invoke --resource-group $ResourceGroupName --name $DomainController2 --command-id RunPowerShellScript --scripts '
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    Import-Module ADDSDeployment
    Install-ADDSDomainController -DomainName $ADForestName -CreateDnsDelegation:$true -Credential (New-Object System.Management.Automation.PSCredential("TWE\Administrator", (ConvertTo-SecureString $ADAdminPassword -AsPlainText -Force))) -DatabasePath "F:\Windows\NTDS" -LogPath "F:\Windows\NTDS" -SysvolPath "F:\Windows\SYSVOL" -NoRebootOnCompletion:$true -Force:$true
'



az vm run-command invoke --resource-group $ResourceGroupName --name $DomainControllerAll --command-id RunPowerShellScript --scripts '

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

# Reboot vms
az vm restart -g $ResourceGroupName -n $DomainControllerAll