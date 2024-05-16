


output "private_ips" {
  description = "Private IP addresses of network interfaces"
  value = [for nic in azurerm_network_interface.nic : nic.ip_configuration[0].private_ip_address]
}


# output "network_interface_ids" {
#   description = "ids of the vm nics provisoned."
#   value       = "${azurerm_network_interface.nic.*.id}"
# }

# output "network_interface_private_ip" {
#   description = "private ip addresses of the vm nics"
#   value       = azurerm_network_interface.nic.*.private_ip_address
# }

# output "dc0_private_ip" {
#   description = "Private IP address of domain controller 1"
#   value       = azurerm_windows_virtual_machine.dc[0].network_interface_ids[0].private_ip_address
# }

# output "dc1_private_ip" {
#   description = "Private IP address of domain controller 2"
#   value       = azurerm_windows_virtual_machine.dc[1].network_interface_ids[0].private_ip_address
# }


# output "domain_controller_private_ips" {
#   description = "Private IP addresses of domain controllers"
#   value = {
#     for idx, dc in azurerm_windows_virtual_machine.dc : 
#     "dc${idx + 1}" => dc.network_interface_ids[0].private_ip_address
#   }
# }
