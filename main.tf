// Resource Groups
resource "azurerm_resource_group" "learning" {
  // Key Values
  name     = var.tags.project-name
  location = var.tf-region

  // Tags
  tags = merge({
      "Name" = var.tags.project-name
    },
    var.global-tags
  )
}

// Virtual Network; define the primary CIDR
resource "azurerm_virtual_network" "primary_cidr" {
  // Resource Group Association
  resource_group_name = azurerm_resource_group.learning.name

  // Key Values
  name                = var.networking.primary_cidr_name
  address_space       = [ var.networking.primary_cidr ]
  location            = azurerm_resource_group.learning.location

  // Tags
  tags = merge({
      "Name" = "${var.tags.project-name} Primary CIDR"
    },
    var.global-tags
  )
}

// Azure Firewall
resource "azurerm_subnet" "azurefirewall" {
  // Resource Group Association
  resource_group_name = azurerm_resource_group.learning.name

  // Key Values
  name                 = "AzureFirewallSubnet"
  virtual_network_name = azurerm_virtual_network.primary_cidr.name
  address_prefixes     = [ var.networking.firewall_subnet ]
}

// Subnet definition
resource "azurerm_subnet" "public_subnets" {
  // For each public subnet...
  for_each = { for name, cidr in var.networking.public_subnets : name => cidr }

  // Resource Group Association
  resource_group_name = azurerm_resource_group.learning.name

  // Key Values
  name                 = each.key
  virtual_network_name = azurerm_virtual_network.primary_cidr.name
  address_prefixes     = [ each.value ]
}

// Creates a Public IP Address
resource "azurerm_public_ip" "k3s-host" {
  // Resource Group Association
  resource_group_name = azurerm_resource_group.learning.name
  location            = azurerm_resource_group.learning.location

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
  resource_group_name = azurerm_resource_group.learning.name
  location            = azurerm_resource_group.learning.location

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

// Defining Virtual Machine Resources - Virtual Machine
resource "azurerm_linux_virtual_machine" "k3s" {
  // Resource Group Association
  resource_group_name = azurerm_resource_group.learning.name
  location            = azurerm_resource_group.learning.location

  // Key Values
  name                = var.k3s-vm.name
  size                = var.k3s-vm.size
  admin_username      = var.ssh_information.username
  network_interface_ids = [
    azurerm_network_interface.k3s-net-int.id,
  ]

  admin_ssh_key {
    username   = var.ssh_information.username
    public_key = var.ssh_information.pubkey
  }

  os_disk {
    caching               = "ReadWrite"
    storage_account_type  = "Standard_LRS"
    disk_size_gb          = var.k3s-vm.disk_size
  }

  source_image_reference {
    publisher = var.k3s-vm.image_references.publisher
    offer     = var.k3s-vm.image_references.offer
    sku       = var.k3s-vm.image_references.sku
    version   = var.k3s-vm.image_references.version
  }
}

// Firewall Rules
resource "azurerm_network_security_group" "k3s_ingress" {
  // Resource Group Association
  resource_group_name = azurerm_resource_group.learning.name
  location            = azurerm_resource_group.learning.location

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
  resource_group_name = azurerm_resource_group.learning.name
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
  resource_group_name = azurerm_resource_group.learning.name
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
  resource_group_name = azurerm_resource_group.learning.name
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
