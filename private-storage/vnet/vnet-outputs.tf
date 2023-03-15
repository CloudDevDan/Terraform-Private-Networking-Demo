output "spoke-vnet-name" {
  value = azurerm_virtual_network.vnet.name
}

output "spoke-vnet-id" {
  value = azurerm_virtual_network.vnet.id
}

output "endpoints-subnet-id" {
  value = azurerm_subnet.subnet.id
}