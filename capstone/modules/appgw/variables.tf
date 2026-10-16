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
  description = "Dedicated Application Gateway subnet."
}

variable "backend_ip" {
  type        = string
  description = "Private IP of the AKS internal load balancer."
}

variable "capacity" {
  type    = number
  default = 1
}

variable "waf_mode" {
  type    = string
  default = "Prevention"

  validation {
    condition     = contains(["Prevention", "Detection"], var.waf_mode)
    error_message = "waf_mode must be Prevention or Detection."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}
