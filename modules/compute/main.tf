// Defining Virtual Machine Resources - Virtual Machine
resource "azurerm_linux_virtual_machine" "host" {
  // Resource Group Association
  resource_group_name = var.resource_group_name
  location            = var.location

  // Key Values
  name                = var.vm-settings.name
  size                = var.vm-settings.size
  admin_username      = var.ssh-settings.username

  // Network Interface IDs
  network_interface_ids = var.net_interface_ids

  admin_ssh_key {
    username   = var.ssh-settings.username
    public_key = var.ssh-settings.pubkey
  }

  os_disk {
    caching               = "ReadWrite"
    storage_account_type  = "Standard_LRS"
    disk_size_gb          = var.vm-settings.disk_size
  }

  source_image_reference {
    publisher = var.vm-settings.image_references.publisher
    offer     = var.vm-settings.image_references.offer
    sku       = var.vm-settings.image_references.sku
    version   = var.vm-settings.image_references.version
  }
}

