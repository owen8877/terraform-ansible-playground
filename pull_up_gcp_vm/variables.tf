variable "project_id" {}
variable "region" { default = "us-east1" }
variable "zone" { default = "us-east1-d" }
variable "machine_type" { default = "e2-micro" }  # has to be this type for free billing
variable "image" {}
variable "disk_size_gb" { default = 30 }          # has to be this size for free billing
variable "disk_type" { default = "pd-standard" }  # has to be this type for free billing

variable "ssh_user" {}
variable "public_key_path" {}
variable "cloudflare_api_token" {}
variable "cloudflare_zone_id" {}

variable "sub_domain" {
  description = "Field of subdomain"
  default     = "unknown"
  validation {
    condition     = var.sub_domain != "unknown"
    error_message = "The value of 'sub_domain' cannot be 'unknown'."
  }
}
variable "name" {
  description = "Name of the VM instance"
  default     = "unknown"
  validation {
    condition     = var.name != "unknown"
    error_message = "The value of 'name' cannot be 'unknown'."
  }
}