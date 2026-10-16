variable "registry_name" {
  type        = string
  description = "Globally unique, 5-50 lowercase letters/numbers."
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
