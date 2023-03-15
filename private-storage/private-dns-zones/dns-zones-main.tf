# Private DNS Zones VNET link
resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_zone_link" {
  for_each              = { for netlink in var.netlink_list : netlink.netlink_name => netlink }
  name                  = "${var.virtual_network_name}-${each.value.netlink_name}"
  resource_group_name   = var.hub_resource_group_name
  private_dns_zone_name = each.value.private_dns_zone_name
  virtual_network_id    = var.virtual_network_id
}