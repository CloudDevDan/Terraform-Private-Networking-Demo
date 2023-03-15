locals {
  app_name                       = "clouddevdan"
  location                       = "UK South"
  resource_group_name            = "tf_private_storage_spoke"
  hub_resource_group_name        = "tf_private_storage_hub"
  virtual_network_name           = "tf_private_storage_spoke_vnet"
  hub_virtual_network_name       = "tf_private_storage_hub_vnet"
  address_space                  = "192.168.0.0/16"
  endpoints_subnet_address_space = "192.168.0.0/24"
  endpoints_subnet_name          = "EndpointsSubnet"
  tags = {
    environment = "dev"
    owner       = "Daniel McLoughlin"
    source      = "terraform"
  }

  netlink_list = [
    {
      netlink_name          = "blob"
      private_dns_zone_name = "privatelink.blob.core.windows.net"
    },
    {
      netlink_name          = "table"
      private_dns_zone_name = "privatelink.table.core.windows.net"
    },
    {
      netlink_name          = "queue"
      private_dns_zone_name = "privatelink.queue.core.windows.net"
    },
    {
      netlink_name          = "vaultcore"
      private_dns_zone_name = "privatelink.vaultcore.azure.net"
    }
  ]

}

# Create the spoke resource group
resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = local.location
  tags     = local.tags
}

# Ref: Hub Resource Group
data "azurerm_resource_group" "hub-rg" {
  name = local.hub_resource_group_name
}

# Ref: Hub VNET
data "azurerm_virtual_network" "hub-vnet" {
  name                = local.hub_virtual_network_name
  resource_group_name = local.hub_resource_group_name
}

# Ref: Hub Private DNS Zones
data "azurerm_private_dns_zone" "dns_zones" {
  for_each            = { for netlink in local.netlink_list : netlink.netlink_name => netlink }
  name                = each.value.private_dns_zone_name
  resource_group_name = data.azurerm_resource_group.hub-rg.name
}

# Deploy the spoke VNET and peer is with the hub VNET
# Create the endpoints subnet
module "vnet" {
  source                         = "./vnet"
  resource_group_name            = azurerm_resource_group.rg.name
  location                       = local.location
  tags                           = local.tags
  virtual_network_name           = local.virtual_network_name
  hub_resource_group_name        = data.azurerm_resource_group.hub-rg.name
  hub_virtual_network_name       = data.azurerm_virtual_network.hub-vnet.name
  hub_virtual_network_id         = data.azurerm_virtual_network.hub-vnet.id
  address_space                  = local.address_space
  endpoints_subnet_name          = local.endpoints_subnet_name
  endpoints_subnet_address_space = local.endpoints_subnet_address_space
}

# forced time delay to allow vnet peering propagation
resource "time_sleep" "peering_propagation" {
  create_duration = "2m"
  triggers = {
    peering_confirmation = module.vnet.peering_confirmation
  }
}

# Link the hub existing Private DNS Zones to the spoke VNET
module "spoke-private-dns-zones-link" {
  source                  = "./private-dns-zones"
  netlink_list            = local.netlink_list
  hub_resource_group_name = data.azurerm_resource_group.hub-rg.name
  virtual_network_name    = module.vnet.spoke-vnet-name
  virtual_network_id      = module.vnet.spoke-vnet-id
  depends_on = [
    time_sleep.peering_propagation
  ]
}

module "private-key-vault" {
  source               = "./private-key-vault"
  tags                 = local.tags
  app_name             = local.app_name
  location             = local.location
  resource_group_name  = azurerm_resource_group.rg.name
  endpoints_subnet_id  = module.vnet.endpoints-subnet-id
  private_dns_zone_ids = data.azurerm_private_dns_zone.dns_zones
  depends_on = [
    time_sleep.peering_propagation
  ]
}

# forced time delay to allow DNS propagation
resource "time_sleep" "vault_endpoint_propagation" {
  create_duration = "2m"

  triggers = {
    propagation = module.private-key-vault.vault_endpoint_propagation
  }
  depends_on = [
    time_sleep.peering_propagation
  ]
}

# Module for storage accounts with private endpoints
# includes containers, tables and queues
# storage account primary key saved as key vault secret
module "private-storage-account" {
  source               = "./private-storage-account"
  count                = var.resource_count
  tags                 = local.tags
  app_name             = local.app_name
  location             = local.location
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = module.vnet.spoke-vnet-name
  endpoints_subnet_id  = module.vnet.endpoints-subnet-id
  private_dns_zone_ids = data.azurerm_private_dns_zone.dns_zones
  key_vault_id         = module.private-key-vault.key_vault_id
  depends_on = [
    time_sleep.vault_endpoint_propagation
  ]
}