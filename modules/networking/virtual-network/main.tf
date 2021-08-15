// Virtual Network; define the primary CIDR
resource "azurerm_virtual_network" "cidr" {
  // Resource Group Association
  resource_group_name = var.resource_group_name

  // Key Values
  name                = var.networking.primary_cidr_name
  address_space       = [ var.networking.primary_cidr ]
  location            = var.location

  // Tags
  tags = merge( var.tags, var.global-tags )
}
