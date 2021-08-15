// Resource Group Settings
variable "resource_group_name" {}
variable "location" {}

// Virtual Machine Settings
variable "vm-settings" {}
variable "ssh-settings" {}

// Network Settings
variable "net_interface_ids" {}

// Tags
variable "tags" { default = {} }
variable "global-tags" { default = {} }
