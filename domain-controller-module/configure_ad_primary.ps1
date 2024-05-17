
Add-WindowsFeature AD-Domain-Services
Import-Module ADDSDeployment

param (
    [Parameter(Mandatory=$true)]
    [string]$DomainName,

    [Parameter(Mandatory=$true)]
    [string]$AdminPassword
)

Install-ADDSForest `
        -DomainName $DomainName `
        -InstallDns `
        -SafeModeAdministratorPassword (ConvertTo-SecureString $AdminPassword -AsPlainText -Force) `
        -Force `
        -Confirm:$false



