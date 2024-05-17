# Get the list of available disks
$Disks = Get-Disk

# Initialize and format each data disk
foreach ($Disk in $Disks) {
    if ($Disk.Size -gt 0 -and $Disk.Size -lt 128000000000) { # Filter disks by size (adjust as needed)
        $VolumeLabel = "DataDisk"
        Initialize-Disk -Number $Disk.Number -PartitionStyle MBR -Confirm:$false
        New-Partition -DiskNumber $Disk.Number -UseMaximumSize -AssignDriveLetter -DriveLetter F -Confirm:$false
        Format-Volume -DriveLetter F -FileSystem NTFS -NewFileSystemLabel $VolumeLabel -Confirm:$false
    }
}

# Set NTP Server
$ntpServer = "time.windows.com"

# Configure NTP Settings
w32tm /config /manualpeerlist:$ntpServer /syncfromflags:manual /reliable:YES /update

# Restart the Windows Time Service
Restart-Service w32time

# Check NTP Configuration
#w32tm /query /status