# Define Variables
variable "resource_group_name" {
  type    = string
}

variable "location" {
  type    = string
  default = "West US"
}

variable "admin_username" {
  type    = string
  default = "twe_admin"
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "dsrm_password" {
  type      = string
  sensitive = true
}

variable "os_disk_size" {
  type    = number
  default = 120
}

variable "data_disk_size" {
  type    = number
  default = 20
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}

variable "vm_name_prefix" {
  type    = string
  default = ""
}

variable "availability_set_name" {
  type    = string
  default = "twe_dc_availability_set"
}

variable "domain_name" {
  type    = string
}

variable "vnet_name" {
  type    = string
  default = "vnet"
}

variable "vnet_address_space" {
  type    = list(string)
  default = ["10.2.0.0/16"]
}

variable "subnet_name" {
  type    = string
  default = "vnet"
}

variable "subnet_address_prefixes" {
  type    = list(string)
  default = ["10.2.1.0/24"]
}

variable "nsg_name" {
  type    = string
  default = "nsg"
}

variable "configure" {
  type  = bool
  default = false
  description = "Do you want Terraform to run AD and VM configuration steps?"
}

variable "configure_via_local" {
  type  = bool
  default = false
  description = "Do you want Terraform to run AD and VM configuration steps?"
}

variable "create_dns" {
  type  = bool
  default = false
  description = "Create a dns delegation on vm?"
}

variable "ntp_server" {
  type  = string
  default = "time.windows.com"
}
