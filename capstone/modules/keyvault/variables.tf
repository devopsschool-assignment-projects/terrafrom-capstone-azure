variable "vault_name" {
  type        = string
  description = "Globally unique, 3-24 chars."
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "banner" {
  type        = string
  description = "Text stored as secret 'app-banner' and shown on the web page."
}

variable "tags" {
  type    = map(string)
  default = {}
}
