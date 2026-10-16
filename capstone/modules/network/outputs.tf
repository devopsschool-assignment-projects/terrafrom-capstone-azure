output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "aks_subnet_id" {
  value = azurerm_subnet.aks.id
}

output "appgw_subnet_id" {
  value = azurerm_subnet.appgw.id
}

output "aks_subnet_prefix" {
  value = azurerm_subnet.aks.address_prefixes[0]
}

# Fixed private IP for the internal load balancer (host .100 of the AKS subnet).
output "internal_lb_ip" {
  value = cidrhost(azurerm_subnet.aks.address_prefixes[0], 100)
}
