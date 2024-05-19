# Prompt the user with instructions and press Enter to continue
Read-Host -Prompt @"
This script is expecting a .csv formatted file with the following headers:
- SamAccountName
- GivenName
- Surname
- UserPrincipalName
- EmailAddress
- Password
- DisplayName
- Department
- Title
- Company

Press Enter to continue...
"@

# Import Active Directory module
Import-Module ActiveDirectory

# Default domain name
$defaultDomainName = "twe-tech-assess.local"

# Prompt user for domain name input
$domainName = Read-Host "Enter the domain name (default: $defaultDomainName)"
if ([string]::IsNullOrWhiteSpace($domainName)) {
    $domainName = $defaultDomainName
}

try{

    $domainDistinguishedName = (Get-ADDomain -Identity $domainName).DistinguishedName
    # Get the Users OU in the domain
    #$ou = Get-ADOrganizationalUnit -Filter { Name -eq "Users" } -SearchBase "DC=$domainName" -ErrorAction Stop

    # # Check if the OU object is retrieved
    # if ($ou) {
    #     $ouPath = $ou.DistinguishedName
    #     Write-Output "Distinguished Name of the 'Users' OU in $domainName is: $ouPath"
    # }
    # else {
    #     Write-Error "OU 'Users' not found in $domainName"
    # }


    # Get the "Users" container in the domain
    $container = Get-ADObject -Filter { Name -eq "Users" -and ObjectClass -eq "Container" } -SearchBase $domainDistinguishedName

    # Check if the OU object is retrieved
    if ($container) {
        $ouPath = $container.DistinguishedName
        Write-Output "Distinguished Name of the 'Users' container in $domainName is: $ouPath"
    }
    else {
        Write-Error "Container 'Users' not found in $domainName"
    }


}catch{
    Write-Error "Ooops, something went wrong!"
}


# Open file dialog
# Load Windows Forms
[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

# Create and show open file dialog
$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.InitialDirectory = $StartDir
$dialog.Filter = "CSV (*.csv)| *.csv"
$dialog.ShowDialog() | Out-Null

# Get file path
$CSVFile = $dialog.FileName

# Import file into variable
# Let's make sure the file path was valid
# If the file path is not valid, then exit the script
if ([System.IO.File]::Exists($CSVFile)) {
    Write-Host "Importing CSV..."
    $CSV = Import-Csv -LiteralPath "$CSVFile"
} else {
    Write-Host "File path specified was not valid"
    Exit
}

foreach ($user in $CSV) {

    # Retrieve user information from CSV objects
    $SamAccountName = $user.SamAccountName
    $username = $SamAccountName
    $GivenName = $user.GivenName
    $Surname = $user.Surname
    $UserPrincipalName = $user.UserPrincipalName
    $EmailAddress = $user.EmailAddress
    $Password = $user.Password
    $DisplayName = $user.DisplayName
    $Department = $user.Department
    $Title = $user.Title
    $Company = $user.Company

    # Check if the user already exists
    $existingUser = Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'" -ErrorAction SilentlyContinue

    if ($null -eq $existingUser) {

        # Confirm user creation
        $createUser = Read-Host "User $username does not exist. Do you want to create this user? (yes/no or y/n)"
        if ($createUser -eq "yes" -or $createUser -eq "y") {

            # Attempt to create a new user
            try {
                New-ADUser `
                    -SamAccountName $SamAccountName `
                    -UserPrincipalName $UserPrincipalName `
                    -Name $DisplayName `
                    -GivenName $GivenName `
                    -Surname $Surname `
                    -EmailAddress $EmailAddress `
                    -Department $Department `
                    -Title $Title `
                    -Company $Company `
                    -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force) `
                    -Enabled $true `
                    -Path $ouPath

                Write-Host "User $SamAccountName created. Password set."

            } catch {
                Write-Host "Error creating user $SamAccountName $_"
            }
            
        } elseif ($createUser -eq "no" -or $createUser -eq "n") {
            Write-Host "User creation declined."
        } else {
            Write-Host "Invalid input. Skipping user creation."
        }
    } else { # if user is existing

        # Confirm user update
        $updateUser = Read-Host "User $username exists. Do you want to update this user with information from CSV? (yes/no or y/n)"
        if ($updateUser -eq "yes" -or $updateUser -eq "y") {

            try {
                # Update existing user
                Set-ADUser `
                    -Identity $existingUser `
                    -GivenName $GivenName `
                    -Surname $Surname `
                    -EmailAddress $EmailAddress

                Write-Host "User $username updated."

                # Ask if you want to update passwords
                $resetPassword = Read-Host "Do you want to reset $username's password? (yes/no or y/n)"
                if ($resetPassword -eq "yes" -or $resetPassword -eq "y") {

                    # Prompt for a new password
                    $newPassword = Read-Host -Prompt "Enter a new password for $($existingUser.SamAccountName)" -AsSecureString

                    try {
                        Set-ADAccountPassword `
                            -Identity $existingUser `
                            -NewPassword (ConvertTo-SecureString $newPassword -AsPlainText -Force) `
                            -Reset

                        Write-Host "User $username's password reset."
                    } catch {
                        Write-Host "Error updating user password for $existingUser $_"
                    }

                } elseif ($resetPassword -eq "no" -or $resetPassword -eq "n") {
                    Write-Host "Password reset declined."
                } else {
                    Write-Host "Invalid input. Skipping password reset."
                }

            } catch {
                Write-Host "Error updating user $existingUser $_"
            }

        } elseif ($updateUser -eq "no" -or $updateUser -eq "n") {
            Write-Host "User update declined."
        } else {
            Write-Host "Invalid input. Skipping user update."
        }
    }

    # Prompt to continue or exit the script
    $continue = Read-Host "Do you want to continue to the next user? 'No' will exit the script. (yes/no or y/n)"
    if ($continue -eq "no" -or $continue -eq "n") {
        Write-Host "Exiting script."
        exit
    }
}
