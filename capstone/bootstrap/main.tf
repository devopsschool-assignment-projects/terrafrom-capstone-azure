# =============================================================================
#  BOOTSTRAP  -  run ONCE by the instructor, before any student.
#
#  Creates the storage account that holds every student's Terraform state
#  (one state file per student), and writes config/backend.hcl so that
#  scripts/deploy.sh knows where to find it.
#
#  Its own state stays local (bootstrap/terraform.tfstate) - keep this folder.
# =============================================================================

terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "location" {
  type    = string
  default = "westus3"
}

resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

resource "azurerm_resource_group" "state" {
  name     = "rg-cap-tfstate"
  location = var.location
  tags     = { project = "capstone", purpose = "terraform-state" }
}

resource "azurerm_storage_account" "state" {
  name                            = "stcaptf${random_string.suffix.result}"
  resource_group_name             = azurerm_resource_group.state.name
  location                        = azurerm_resource_group.state.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                            = azurerm_resource_group.state.tags
}

resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

resource "local_file" "backend_hcl" {
  filename = "${path.module}/../config/backend.hcl"
  content  = <<-EOT
    resource_group_name  = "${azurerm_resource_group.state.name}"
    storage_account_name = "${azurerm_storage_account.state.name}"
    container_name       = "${azurerm_storage_container.state.name}"
  EOT
}

output "state_storage_account" {
  value = azurerm_storage_account.state.name
}
