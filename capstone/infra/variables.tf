variable "student_id" {
  type        = string
  description = "Which student this deployment is for. Must exist in config/master-values.yaml, e.g. student03."

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,11}$", var.student_id))
    error_message = "student_id must be 2-12 lowercase letters/numbers, starting with a letter (e.g. student03)."
  }
}

variable "cloudflare_api_token" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Cloudflare token (Zone > DNS > Edit). Loaded from config/secrets.env by the scripts (TF_VAR_cloudflare_api_token)."
}
