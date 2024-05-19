provider "vsphere" {
  user           = "your-vsphere-username"
  password       = "your-vsphere-password"
  vsphere_server = "vcenter-server-ip"

  # If you have a self-signed cert
  allow_unverified_ssl = true
}


variable "esxi_hosts" {
  default = [
    "esxi-01.example.com",
    "esxi-02.example.com",
    "esxi-03.example.com",
  ]
}

variable "network_interfaces" {
  default = [
    "vmnic0",
    "vmnic1",
    "vmnic2",
    "vmnic3",
  ]
}

data "vsphere_datacenter" "datacenter" {
  name = "dc-01"
}

data "vsphere_host" "host" {
  count         = length(var.esxi_hosts)
  name          = var.esxi_hosts[count.index]
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

resource "vsphere_distributed_virtual_switch" "vds" {
  count         = 41
  name          = "vSwitch${count.index}"
  datacenter_id = data.vsphere_datacenter.datacenter.id

  uplinks         = ["uplink1", "uplink2", "uplink3", "uplink4"]
  active_uplinks  = ["uplink1", "uplink2"]
  standby_uplinks = ["uplink3", "uplink4"]

  host {
    host_system_id = data.vsphere_host.host.0.id
    devices        = ["${var.network_interfaces}"]
  }

  host {
    host_system_id = data.vsphere_host.host.1.id
    devices        = ["${var.network_interfaces}"]
  }

  host {
    host_system_id = data.vsphere_host.host.2.id
    devices        = ["${var.network_interfaces}"]
  }
}