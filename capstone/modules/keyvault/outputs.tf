output "id" {
  value = azurerm_key_vault.this.id
}

output "name" {
  value = azurerm_key_vault.this.name
}

output "vault_uri" {
  value = azurerm_key_vault.this.vault_uri
}

output "db_password" {
  value     = random_password.db.result
  sensitive = true
}

# Depend on this when something must wait until the secrets exist.
output "secrets_ready" {
  value = [azurerm_key_vault_secret.db_password.id, azurerm_key_vault_secret.banner.id]
}
