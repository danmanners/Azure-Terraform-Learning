// Resource Groups
module "azure_resource_group" {
  // Module Source Directory
  source = "./modules/resource-groups"
  // Variables
  tf-region = var.tf-region
  // Tags
  tags = var.tags
  global-tags = var.global-tags
}

// Virtual Network; define the primary CIDR
module "virtual_net" {
  // Module Source Directory
  source = "./modules/networking/virtual-network"
  // Resource Group Association
  resource_group_name = module.azure_resource_group.resource_group_name
  location            = module.azure_resource_group.location
  // Variables
  networking          = var.networking
  // Tags
  tags        = var.tags
  global-tags = var.global-tags
}


// Subnet definition
resource "azurerm_subnet" "public_subnets" {
  // For each public subnet...
  for_each = { for name, cidr in var.networking.public_subnets : name => cidr }

  // Resource Group Association
  resource_group_name = module.azure_resource_group.resource_group_name

  // Key Values
  name                 = each.key
  virtual_network_name = module.virtual_net.name
  address_prefixes     = [ each.value ]
}

// Creates a Public IP Address
resource "azurerm_public_ip" "k3s-host" {
  // Resource Group Association
  resource_group_name = module.azure_resource_group.resource_group_name
  location            = module.azure_resource_group.location

  // Key Values
  name                = lower("${var.k3s-vm.name}-public-ip")
  allocation_method   = "Static"
  sku = "Standard"

  // Tags
  tags = merge({
      "Name" = "${var.tags.project-name}-public-ip"
    },
    var.global-tags
  )
}

// Defining Virtual Machine Resources - Networking
resource "azurerm_network_interface" "k3s-net-int" {
  // Resource Group Association
  resource_group_name = module.azure_resource_group.resource_group_name
  location            = module.azure_resource_group.location

  // Key Values
  name                  = "${var.networking.primary_cidr_name}-${var.k3s-vm.name}-nic"
  enable_ip_forwarding  = true

  // IP Configuration
  ip_configuration {
    name                          = var.k3s-vm.eni.name
    subnet_id                     = azurerm_subnet.public_subnets[var.k3s-vm.eni.subnet].id
    public_ip_address_id          = azurerm_public_ip.k3s-host.id
    private_ip_address_allocation = "Dynamic"
  }

  // Tags
  tags = merge({
      "Name" = "${var.tags.project-name}-${var.k3s-vm.eni.name}"
    },
    var.global-tags
  )

  depends_on = [
    azurerm_public_ip.k3s-host
  ]
}

module "k3s-host" {
  // Module Source Directory
  source = "./modules/compute"
  // Resource Group Association
  resource_group_name = module.azure_resource_group.resource_group_name
  location            = module.azure_resource_group.location
  // Variables
  vm-settings         = var.k3s-vm
  ssh-settings        = var.ssh_information
  net_interface_ids   = toset([ azurerm_network_interface.k3s-net-int.id ])
  // Tags
  tags        = var.tags
  global-tags = var.global-tags
}

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

resource "azurerm_network_interface_security_group_association" "secure_k3s_ingress" {
  network_interface_id          = azurerm_network_interface.k3s-net-int.id
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

resource "azurerm_network_security_rule" "icmp_inbound" {
  // Resource Group Association
  resource_group_name = module.azure_resource_group.resource_group_name
  network_security_group_name = azurerm_network_security_group.k3s_ingress.name

  // Key Values
  name                        = "icmp_inbound"
  priority                    = 103
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Icmp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = azurerm_public_ip.k3s-host.ip_address
}

resource "azurerm_network_security_rule" "traffic_outbound" {
  // Resource Group Association
  resource_group_name = module.azure_resource_group.resource_group_name
  network_security_group_name = azurerm_network_security_group.k3s_ingress.name

  // Key Values
  name                        = "traffic_outbound"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = azurerm_public_ip.k3s-host.ip_address
  destination_address_prefix  = "*"
}
