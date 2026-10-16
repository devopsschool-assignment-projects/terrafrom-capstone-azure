output "public_ip" {
  value = azurerm_public_ip.this.ip_address
}

output "name" {
  value = azurerm_application_gateway.this.name
}
