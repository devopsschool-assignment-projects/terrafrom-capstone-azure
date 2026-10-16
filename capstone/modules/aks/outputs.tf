output "id" {
  value = azurerm_kubernetes_cluster.this.id
}

output "name" {
  value = azurerm_kubernetes_cluster.this.name
}

output "oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "kube_host" {
  value = azurerm_kubernetes_cluster.this.kube_admin_config[0].host
}

output "kube_client_certificate" {
  value     = azurerm_kubernetes_cluster.this.kube_admin_config[0].client_certificate
  sensitive = true
}

output "kube_client_key" {
  value     = azurerm_kubernetes_cluster.this.kube_admin_config[0].client_key
  sensitive = true
}

output "kube_cluster_ca_certificate" {
  value     = azurerm_kubernetes_cluster.this.kube_admin_config[0].cluster_ca_certificate
  sensitive = true
}
