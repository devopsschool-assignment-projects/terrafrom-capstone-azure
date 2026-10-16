output "student" {
  value = var.student_id
}

output "app_url" {
  description = "Open this in your browser."
  value       = "http://${module.dns.app_fqdn}"
}

output "app_public_ip" {
  description = "Application Gateway public IP (works even before DNS has propagated)."
  value       = module.appgw.public_ip
}

output "resource_group" {
  value = azurerm_resource_group.this.name
}

output "aks_cluster" {
  value = module.aks.name
}

output "get_credentials_command" {
  value = "az aks get-credentials -g ${azurerm_resource_group.this.name} -n ${module.aks.name} --overwrite-existing"
}

output "acr_login_server" {
  value = module.acr.login_server
}

output "key_vault" {
  value = module.keyvault.name
}

output "storage_account" {
  value = module.storage.account_name
}

output "dns_zone" {
  value = module.dns.zone_name
}

output "dns_name_servers" {
  value = module.dns.name_servers
}
