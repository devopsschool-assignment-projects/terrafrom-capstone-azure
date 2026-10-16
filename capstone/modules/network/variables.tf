variable "name" {
  type        = string
  description = "Name suffix used for all resources, e.g. cap-student01."
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "address_space" {
  type        = string
  description = "VNet CIDR, e.g. 10.1.0.0/16."
}

variable "tags" {
  type    = map(string)
  default = {}
}
