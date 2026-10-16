# Workload-identity module (Microsoft Entra ID for pods).
#
# The backend pod gets its OWN Entra identity. Kubernetes proves who the pod is
# (a signed token from the cluster's OIDC issuer), Entra ID trusts that token
# through a "federated credential", and the pod can then read Key Vault
# secrets - without any password stored anywhere.

resource "azurerm_user_assigned_identity" "backend" {
  name                = "id-${var.name}-backend"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "backend" {
  name      = "backend-pod"
  parent_id = azurerm_user_assigned_identity.backend.id
  issuer    = var.oidc_issuer_url
  subject   = "system:serviceaccount:${var.namespace}:${var.service_account}"
  audience  = ["api://AzureADTokenExchange"]
}

resource "azurerm_role_assignment" "read_secrets" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.backend.principal_id
}
