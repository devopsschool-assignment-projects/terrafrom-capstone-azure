output "zone_name" {
  value = azurerm_dns_zone.this.name
}

output "name_servers" {
  value = azurerm_dns_zone.this.name_servers
}

output "app_fqdn" {
  value = "app.${azurerm_dns_zone.this.name}"
}
