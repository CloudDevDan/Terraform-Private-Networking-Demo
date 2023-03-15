locals {
  private_endpoints = ["blob", "table", "queue"]
}

# used for random uuid in storage names
resource "random_uuid" "ruuid" {}

# Storage
resource "azurerm_storage_account" "example" {
  name                     = substr(replace("${var.app_name}${random_uuid.ruuid.result}", "-", ""), 0, 23)
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

resource "azurerm_key_vault_secret" "storage_key" {
  name         = "${azurerm_storage_account.example.name}-k1"
  value        = azurerm_storage_account.example.primary_connection_string
  key_vault_id = var.key_vault_id
  content_type = "text/plain"
}

resource "azurerm_storage_account_network_rules" "example" {
  storage_account_id = azurerm_storage_account.example.id
  default_action     = "Deny"
  ip_rules           = []
  bypass             = ["None"]
  depends_on = [
    azurerm_storage_container.example,
    azurerm_storage_queue.example,
    azurerm_storage_table.example,
    azurerm_private_endpoint.private_endpoint
  ]
}

resource "azurerm_storage_container" "example" {
  count                 = 2
  name                  = "content${count.index}"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
}

resource "azurerm_storage_queue" "example" {
  count                = 2
  name                 = "mysamplequeue${count.index}"
  storage_account_name = azurerm_storage_account.example.name
}

resource "azurerm_storage_table" "example" {
  count                = 2
  name                 = "mysampletable${count.index}"
  storage_account_name = azurerm_storage_account.example.name
}

# Private Endpoints
resource "azurerm_private_endpoint" "private_endpoint" {
  for_each            = toset(local.private_endpoints)
  name                = "pe-${each.key}-${azurerm_storage_account.example.name}"
  tags                = var.tags
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.endpoints_subnet_id

  private_service_connection {
    name                           = "pe-${each.key}-${azurerm_storage_account.example.name}"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.example.id
    subresource_names              = ["${each.key}"]
  }

  private_dns_zone_group {
    name                 = "private-dns-zone-group"
    private_dns_zone_ids = [var.private_dns_zone_ids[each.key].id]
  }

  depends_on = [
    azurerm_storage_container.example,
    azurerm_storage_queue.example,
    azurerm_storage_table.example
  ]

}