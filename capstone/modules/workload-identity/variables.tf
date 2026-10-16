variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "oidc_issuer_url" {
  type        = string
  description = "OIDC issuer URL of the AKS cluster."
}

variable "namespace" {
  type    = string
  default = "capstone"
}

variable "service_account" {
  type    = string
  default = "backend"
}

variable "key_vault_id" {
  type        = string
  description = "Vault the backend may read secrets from."
}

variable "tags" {
  type    = map(string)
  default = {}
}
