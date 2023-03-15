locals {
  private_endpoints = "vaultcore"
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "example" {
  name                = "${var.app_name}-kv"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
  
  enabled_for_disk_encryption = false
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge", "Recover", "Restore"
    ]

  }

  network_acls {
    default_action = "Deny"
    ip_rules       = []
    bypass         = "None"
  }
}

# Private Endpoint
resource "azurerm_private_endpoint" "private_endpoint" {
  name                = "pe-${local.private_endpoints}-${azurerm_key_vault.example.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.endpoints_subnet_id

  private_service_connection {
    name                           = "pe-${local.private_endpoints}-${azurerm_key_vault.example.name}"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_key_vault.example.id
    subresource_names              = ["vault"] # hardcoded as not "vaultcore" for this type
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_ids[local.private_endpoints].id]
  }

}