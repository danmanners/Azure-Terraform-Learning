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

// Firewalling
resource "azurerm_firewall" "k3s-ingress" {
  // Resource Group Association
  resource_group_name = azurerm_resource_group.learning.name
  location            = azurerm_resource_group.learning.location

  // Key Values
  name                = var.k3s-firewall.name

  ip_configuration {
    name                 = "${var.tags.project-name}-azure-firewall"
    subnet_id            = azurerm_subnet.azurefirewall.id
    public_ip_address_id = azurerm_public_ip.k3s-host.id
  }

  // Depends on the public IP being available
  depends_on=[
    azurerm_public_ip.k3s-host
  ]

}

// Firewall Rules
resource "azurerm_firewall_nat_rule_collection" "tcp_ingress" {
  // Resource Group Association
  resource_group_name = azurerm_resource_group.learning.name

  // Key Values
  name                = "k3s_ingress"
  azure_firewall_name = azurerm_firewall.k3s-ingress.name
  priority            = 100
  action              = "Dnat"

  rule {
    name = "22_ssh_inbound"
    source_addresses      = var.k3s-firewall.ingress_rules.source_addresses
    destination_ports     = [ "22" ]
    destination_addresses = [ azurerm_public_ip.k3s-host.ip_address ]
    translated_address    = azurerm_network_interface.k3s-net-int.private_ip_address
    translated_port       = "22"
    protocols = var.k3s-firewall.ingress_rules.protocols
  }

  rule {
    name = "80_http_inbound"
    source_addresses      = var.k3s-firewall.ingress_rules.source_addresses
    destination_ports     = [ "80" ]
    destination_addresses = [ azurerm_public_ip.k3s-host.ip_address ]
    translated_address    = azurerm_network_interface.k3s-net-int.private_ip_address
    translated_port       = "80"
    protocols = var.k3s-firewall.ingress_rules.protocols
  }

  rule {
    name = "443_https_inbound"
    source_addresses      = var.k3s-firewall.ingress_rules.source_addresses
    destination_ports     = [ "443" ]
    destination_addresses = [ azurerm_public_ip.k3s-host.ip_address ]
    translated_address    = azurerm_network_interface.k3s-net-int.private_ip_address
    translated_port       = "443"
    protocols = var.k3s-firewall.ingress_rules.protocols
  }
}
