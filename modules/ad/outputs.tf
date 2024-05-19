output "dc_private_ips" {
  value = [
    azurerm_network_interface.nic[0].private_ip_address,
    azurerm_network_interface.nic[1].private_ip_address
  ]
}


output "nic_private_ips" {
  value = [for nic in azurerm_network_interface.nic : nic.ip_configuration[0].private_ip_address]
}
