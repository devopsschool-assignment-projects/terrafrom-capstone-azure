variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  type        = string
  description = "Subnet for the worker nodes."
}

variable "identity_id" {
  type        = string
  description = "Resource ID of the user-assigned identity for the control plane."
}

variable "acr_id" {
  type        = string
  description = "Registry the nodes may pull from."
}

variable "node_vm_size" {
  type    = string
  default = "Standard_D2s_v6"
}

variable "node_count" {
  type    = number
  default = 1
}

variable "kubernetes_version" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
