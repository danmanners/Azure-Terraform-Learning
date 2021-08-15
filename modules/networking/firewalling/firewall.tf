// Firewall Rules
resource "azurerm_network_security_group" "k3s_ingress" {
  // Resource Group Association
  resource_group_name = module.azure_resource_group.resource_group_name
  location            = module.azure_resource_group.location

  // Key Values
  name                = "${var.tags.project-name}-k3s_ingress"

  // Tags
  tags = var.global-tags
}


resource "azurerm_subnet_network_security_group_association" "secure_k3s_ingress" {
  subnet_id                 = azurerm_subnet.public_subnets[var.k3s-vm.eni.subnet].id
  network_security_group_id = azurerm_network_security_group.k3s_ingress.id
}

resource "azurerm_network_security_rule" "ssh_22_inbound" {
  // Resource Group Association
  resource_group_name = module.azure_resource_group.resource_group_name
  network_security_group_name = azurerm_network_security_group.k3s_ingress.name

  // Key Values
  name                        = "ssh_22_inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = azurerm_public_ip.k3s-host.ip_address
}

resource "azurerm_network_security_rule" "http_80_inbound" {
  // Resource Group Association
  resource_group_name = module.azure_resource_group.resource_group_name
  network_security_group_name = azurerm_network_security_group.k3s_ingress.name

  // Key Values
  name                        = "http_80_inbound"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = azurerm_public_ip.k3s-host.ip_address
}

resource "azurerm_network_security_rule" "https_443_inbound" {
  // Resource Group Association
  resource_group_name = module.azure_resource_group.resource_group_name
  network_security_group_name = azurerm_network_security_group.k3s_ingress.name

  // Key Values
  name                        = "https_443_inbound"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = azurerm_public_ip.k3s-host.ip_address
}
