# Storage module: a storage account with a private "db-backups" container.
# (The database itself runs on an Azure Disk via a PersistentVolumeClaim.
#  This account is where students can store database backups - see the
#  stretch exercises in docs/LAB-GUIDE.md.)

resource "azurerm_storage_account" "this" {
  name                            = var.account_name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                            = var.tags
}

resource "azurerm_storage_container" "backups" {
  name                  = "db-backups"
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}
