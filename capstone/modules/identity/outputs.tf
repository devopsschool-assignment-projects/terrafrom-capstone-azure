output "aks_identity_id" {
  value = azurerm_user_assigned_identity.aks.id
}

output "aks_identity_principal_id" {
  value = azurerm_user_assigned_identity.aks.principal_id
}

# Pass this to the AKS module's depends_on so the role exists before the cluster.
output "network_role_assignment_id" {
  value = azurerm_role_assignment.aks_network.id
}
