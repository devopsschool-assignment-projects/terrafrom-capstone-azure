# =============================================================================
#  ROOT MODULE
#  Reads ONE master file, picks the student's row, and calls the child modules.
#  Every value comes from config/master-values.yaml - nothing is hard-coded here.
# =============================================================================

locals {
  cfg = yamldecode(file("${path.module}/../config/master-values.yaml"))
  g   = local.cfg.global

  # Row of the student being deployed (null when the id is not in the file;
  # the precondition on the resource group turns that into a clear error).
  student = try(local.cfg.students[var.student_id], null)
  index   = try(local.student.index, 0)

  name = "${local.g.prefix}-${var.student_id}" # e.g. cap-student01

  tags = merge(local.g.tags, {
    student    = var.student_id
    managed_by = "terraform"
  })

  # Names that must be globally unique get a short random suffix.
  acr_name     = "${local.g.prefix}${var.student_id}${random_string.suffix.result}"
  kv_name      = "kv-${local.g.prefix}-${var.student_id}-${random_string.suffix.result}"
  storage_name = "st${local.g.prefix}${var.student_id}${random_string.suffix.result}"

  zone_name = "${var.student_id}.${local.g.base_domain}"

  # Image tag changes whenever the app source changes -> pods roll automatically.
  app_files = sort(fileset("${path.module}/../app", "**"))
  image_tag = substr(sha1(join("", [for f in local.app_files : filesha1("${path.module}/../app/${f}")])), 0, 10)
}

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name}"
  location = local.g.location
  tags     = local.tags

  lifecycle {
    precondition {
      condition     = local.student != null
      error_message = "student_id '${var.student_id}' is not listed in config/master-values.yaml."
    }
  }
}

# ---------------------------------------------------------------- network ----
module "network" {
  source = "../modules/network"

  name                = local.name
  location            = local.g.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = "10.${local.index}.0.0/16"
  tags                = local.tags
}

# --------------------------------------------------- identity (Entra ID) -----
module "identity" {
  source = "../modules/identity"

  name                = local.name
  location            = local.g.location
  resource_group_name = azurerm_resource_group.this.name
  vnet_id             = module.network.vnet_id
  tags                = local.tags
}

# -------------------------------------------------------------- registry -----
module "acr" {
  source = "../modules/acr"

  registry_name       = local.acr_name
  location            = local.g.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

# ------------------------------------------------------------- key vault -----
module "keyvault" {
  source = "../modules/keyvault"

  vault_name          = local.kv_name
  location            = local.g.location
  resource_group_name = azurerm_resource_group.this.name
  banner              = local.student.banner
  tags                = local.tags
}

# ---------------------------------------------------------------- storage ----
module "storage" {
  source = "../modules/storage"

  account_name        = local.storage_name
  location            = local.g.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

# -------------------------------------------------------------------- aks ----
module "aks" {
  source = "../modules/aks"

  name                = local.name
  location            = local.g.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.network.aks_subnet_id
  identity_id         = module.identity.aks_identity_id
  acr_id              = module.acr.id
  node_vm_size        = local.g.node_vm_size
  node_count          = local.g.node_count
  kubernetes_version  = try(local.g.kubernetes_version, null)
  tags                = local.tags

  # The cluster identity must be allowed on the VNet before the cluster starts.
  depends_on = [module.identity]
}

# --------------------------------- pod identity (Entra ID workload identity) --
module "workload_identity" {
  source = "../modules/workload-identity"

  name                = local.name
  location            = local.g.location
  resource_group_name = azurerm_resource_group.this.name
  oidc_issuer_url     = module.aks.oidc_issuer_url
  key_vault_id        = module.keyvault.id
  tags                = local.tags
}

# ----------------------------------------------------- build the 3 images ----
# Runs scripts/build-images.sh: builds frontend + backend inside ACR and copies
# the PostgreSQL image into ACR. Re-runs only when the app code changes.
resource "terraform_data" "images" {
  triggers_replace = [local.image_tag, module.acr.name]

  provisioner "local-exec" {
    command = "${path.module}/../scripts/build-images.sh ${module.acr.name} ${local.image_tag} ${local.g.postgres_image}"
  }
}

# -------------------------------------------------------------- app on aks ---
module "app" {
  source = "../modules/k8s-app"

  student_id                  = var.student_id
  registry                    = module.acr.login_server
  image_tag                   = local.image_tag
  postgres_image              = local.g.postgres_image
  db_password                 = module.keyvault.db_password
  key_vault_uri               = module.keyvault.vault_uri
  workload_identity_client_id = module.workload_identity.client_id
  internal_lb_ip              = module.network.internal_lb_ip

  depends_on = [
    terraform_data.images,
    module.keyvault,
    module.workload_identity,
    module.aks,
  ]
}

# ---------------------------------------------------- application gateway ----
module "appgw" {
  source = "../modules/appgw"

  name                = local.name
  location            = local.g.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = module.network.appgw_subnet_id
  backend_ip          = module.network.internal_lb_ip
  capacity            = local.g.appgw_capacity
  waf_mode            = local.g.waf_mode
  tags                = local.tags
}

# -------------------------------------------------------------------- dns ----
module "dns" {
  source = "../modules/dns"

  zone_name                    = local.zone_name
  resource_group_name          = azurerm_resource_group.this.name
  app_ip                       = module.appgw.public_ip
  enable_cloudflare_delegation = local.g.enable_cloudflare_delegation
  cloudflare_zone_id           = local.g.cloudflare_zone_id
  tags                         = local.tags
}
