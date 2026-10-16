variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "vnet_id" {
  type        = string
  description = "VNet the cluster identity may manage (for the internal load balancer)."
}

variable "tags" {
  type    = map(string)
  default = {}
}
