output "azurevm-public-ip" {
    value = azurerm_public_ip.k3s-host.ip_address
}