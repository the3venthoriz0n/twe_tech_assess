variable "rg_name" {
  description = "Existing resource group"
  type        = string
  default     = "Candidate-2731"
}

variable "location" {
  type    = string
  default = "West US"
}

variable "vdi_username" {
  type    = string
  default = "vdi_user"
}

variable "vdi_password" {
  type      = string
  sensitive = true
}

variable "ad_admin_password" {
  description = "Password for AD Administrator"
  type        = string
  sensitive   = true
}