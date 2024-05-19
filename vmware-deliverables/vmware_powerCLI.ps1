# Connect to vCenter Server
Connect-VIServer -Server vcenter-server-ip -User your-vsphere-username -Password your-vsphere-password

# Get the ESXi host
$esxiHost = Get-VMHost -Name "Lab-esxi-01"

# Define the virtual switches
$vSwitchNames = @(
    "vSwitch0", "vSwitch1", "vSwitch2", "vSwitch3", "vSwitch4",
    "vSwitch5", "vSwitch6", "vSwitch7", "vSwitch8", "vSwitch9",
    "vSwitch10", "vSwitch11", "vSwitch12", "vSwitch13", "vSwitch14",
    "vSwitch15", "vSwitch16", "vSwitch17", "vSwitch18", "vSwitch19",
    "vSwitch20", "vSwitch21", "vSwitch22", "vSwitch23", "vSwitch24",
    "vSwitch25", "vSwitch26", "vSwitch27", "vSwitch28", "vSwitch29",
    "vSwitch30", "vSwitch31", "vSwitch32", "vSwitch33", "vSwitch34",
    "vSwitch35", "vSwitch36", "vSwitch37", "vSwitch38", "vSwitch39",
    "vSwitch40"
)

# Create the virtual switches
foreach ($vSwitchName in $vSwitchNames) {
    New-VirtualSwitch -VMHost $esxiHost -Name $vSwitchName -Nic (Get-VMHostNetworkAdapter -VMHost $esxiHost)
}

# Disconnect from vCenter Server
Disconnect-VIServer -Confirm:$false
