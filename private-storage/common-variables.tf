# app name 
variable "app_name" {
  type        = string
  description = "This variable defines the application name used to build resources"
}

# azure region
variable "location" {
  type        = string
  description = "Azure region where the resource group will be created"
  default     = "UK South"
}

variable "resource_count" {
  type        = number
  description = "The number of variable resouces to deploy"
}