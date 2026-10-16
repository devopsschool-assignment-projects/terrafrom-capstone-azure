provider "azurerm" {
  # Uses the subscription you are logged in to (az login), unless the master file sets one.
  subscription_id = try(local.cfg.global.subscription_id, null)

  features {
    key_vault {
      purge_soft_delete_on_destroy = true # so destroy + redeploy with the same names works
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Talks to the cluster that this same run creates (local admin credentials).
provider "kubernetes" {
  host                   = module.aks.kube_host
  client_certificate     = base64decode(module.aks.kube_client_certificate)
  client_key             = base64decode(module.aks.kube_client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_cluster_ca_certificate)
}

# Only used when enable_cloudflare_delegation is true. The token comes from CLOUDFLARE_API_TOKEN in
# config/secrets.env (scripts export it as TF_VAR_cloudflare_api_token). The placeholder keeps the
# provider happy when no token is given (nothing is created in that case).
provider "cloudflare" {
  api_token = coalesce(var.cloudflare_api_token, "0000000000000000000000000000000000000000")
}
