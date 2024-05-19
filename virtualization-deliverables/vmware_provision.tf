provider "vsphere" {
  user           = "your_username"
  password       = "your_password"
  vsphere_server = "vcenter_server_ip"

  # If you have self-signed certs or want to ignore cert validation
  allow_unverified_ssl = true
}

# Define your virtual switches
variable "virtual_switches" {
  type = list(string)
  default = [
    "switch1",
    "switch2",
    "switch3"
    # Add more switches as needed
  ]
}

# Create a datacenter
resource "vsphere_datacenter" "dc" {
  name = "Datacenter"
}

# Create virtual switches
resource "vsphere_virtual_switch" "vswitch" {
  count         = length(var.virtual_switches)
  name          = var.virtual_switches[count.index]
  datacenter_id = vsphere_datacenter.dc.id
}
