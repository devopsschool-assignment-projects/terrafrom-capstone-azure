output "client_id" {
  value = azurerm_user_assigned_identity.backend.client_id
}

output "role_assignment_id" {
  value = azurerm_role_assignment.read_secrets.id
}
