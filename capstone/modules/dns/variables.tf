variable "zone_name" {
  type        = string
  description = "Full subdomain zone, e.g. student03.lab.collabgigs.com."
}

variable "resource_group_name" {
  type = string
}

variable "app_ip" {
  type        = string
  description = "Public IP the 'app' name should point to (the Application Gateway)."
}

variable "enable_cloudflare_delegation" {
  type    = bool
  default = true
}

variable "cloudflare_zone_id" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
