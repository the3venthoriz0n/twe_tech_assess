
Add-WindowsFeature AD-Domain-Services

param (
    [Parameter(Mandatory=$true)]
    [string]$DomainName,

    [Parameter(Mandatory=$true)]
    [string]$AdminPassword
)

Install-ADDSDomainController `
        -DomainName $DomainName `
        -Credential (Get-Credential) `
        -SafeModeAdministratorPassword (ConvertTo-SecureString $AdminPassword -AsPlainText -Force) `
        -Force `
        -Confirm:$false `
        -NoGlobalCatalog:$false `
        -InstallDns:$true `
        -NoRebootOnCompletion:$false `
        -Path "F:\Windows\NTDS" `
        -SysvolPath "F:\Windows\SYSVOL"


        