variable "app_name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "endpoints_subnet_id" { type = string }
variable "private_dns_zone_ids" {}
variable "tags" { type = map(any) }