output "key_vault_id" {
  value = azurerm_key_vault.example.id
}

output "vault_endpoint_propagation" {
  value = azurerm_private_endpoint.private_endpoint.id
}