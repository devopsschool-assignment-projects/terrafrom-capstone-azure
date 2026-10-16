# Identity module (Microsoft Entra ID): the AKS control plane gets a
# user-assigned managed identity - no passwords, no service principal secrets.
# It needs "Network Contributor" on the VNet so AKS can create the internal
# load balancer inside our subnet.

resource "azurerm_user_assigned_identity" "aks" {
  name                = "id-${var.name}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_role_assignment" "aks_network" {
  scope                = var.vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}
