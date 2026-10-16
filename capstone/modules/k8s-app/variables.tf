variable "student_id" {
  type = string
}

variable "registry" {
  type        = string
  description = "ACR login server, e.g. capstudent01abcd.azurecr.io."
}

variable "image_tag" {
  type        = string
  description = "Tag of the backend/frontend images (changes when the app code changes)."
}

variable "postgres_image" {
  type    = string
  default = "postgres:16-alpine"
}

variable "db_name" {
  type    = string
  default = "capstone"
}

variable "db_user" {
  type    = string
  default = "capstone"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "key_vault_uri" {
  type = string
}

variable "workload_identity_client_id" {
  type        = string
  description = "Client ID of the backend's Entra ID identity."
}

variable "internal_lb_ip" {
  type        = string
  description = "Private IP for the frontend's internal load balancer."
}
