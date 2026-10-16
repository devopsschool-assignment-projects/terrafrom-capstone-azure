# Azure Container Registry: private place to store the 3 container images.
# Admin user is OFF - the cluster pulls images using its own identity (AcrPull).

resource "azurerm_container_registry" "this" {
  name                = var.registry_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false
  tags                = var.tags
}
