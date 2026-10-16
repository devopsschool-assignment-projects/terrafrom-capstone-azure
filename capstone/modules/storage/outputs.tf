output "account_name" {
  value = azurerm_storage_account.this.name
}

output "backup_container" {
  value = azurerm_storage_container.backups.name
}
