
# Export list from AD
#Get-ADUser -Filter * -SearchBase "OU=Research,OU=Users,DC=ad,DC=contoso,DC=com" -Properties * | Select-Object name | export-csv -path c:\temp\userexport.csv

param (
    [string]$CSVPath
)

# Validate if the CsvPath parameter is provided
if (-not $CSVPath) {
    Write-Host "Please provide the path to the CSV file using the -CSVPath parameter."
    exit 1
}

# Import-CSV function to import user data
Import-CSV -Path $CSVPath | ForEach-Object {



# Retrieve user information from CSV
$username = $_.Username
$password = $_.Password
$firstName = $_.FirstName
$lastName = $_.LastName
$email = $_.Email

# Check if the user already exists
$user = Get-ADUser -Filter "SamAccountName -eq '$username'" -ErrorAction SilentlyContinue

if ($null -eq $user) { # If user equals null, or doesnt exist
    # Create a new user
    New-ADUser `
        -SamAccountName $username `
        -UserPrincipalName "$username@yourdomain.com" `
        -Name "$firstName $lastName" `
        -GivenName $firstName `
        -Surname $lastName `
        -EmailAddress $email `
        -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) `
        -Enabled $true `
        -Path "OU=Users,DC=yourdomain,DC=com"
    
    Write-Host "User $username created. Password set."

} else { # If user exists
    # Update existing user
    Set-ADUser `
        -Identity $user `
        -GivenName $firstName `
        -Surname $lastName `
        -EmailAddress $email

    Write-Host "User $username updated."


    # Ask if you want to update passwords
    $ResetPassword = Read-Host "Do you want to reset $user password? (yes/no or y/n)"

    if ($resetPassword -eq "yes" -or $resetPassword -eq "y") {
        Write-Host "Password reset initiated."
        

        Set-ADAccountPassword `
            -Identity $user `
            -NewPassword (ConvertTo-SecureString $password -AsPlainText -Force) `
            -Reset

        Write-Host "User $username password reset."


    } elseif ($resetPassword -eq "no" -or $resetPassword -eq "n") {
        Write-Host "Password reset declined."
        

    } else {
        Write-Host "Invalid input. Please enter 'yes'/'y' or 'no'/'n'."
    }


    }
}

