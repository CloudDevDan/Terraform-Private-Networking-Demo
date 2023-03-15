variable "app_name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "virtual_network_name" { type = string }
variable "endpoints_subnet_id" { type = string }
variable "private_dns_zone_ids" {}
variable "key_vault_id" { type = string }
variable "tags" { type = map(any) }