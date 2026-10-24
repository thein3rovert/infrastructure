terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

variable "project_id" {
  type        = string
  description = "GCP project ID that owns the service account"
}

variable "account_id" {
  type        = string
  description = "Service account ID (short name, lowercase, hyphens)"
}

variable "display_name" {
  type        = string
  description = "Human-readable display name"
  default     = ""
}

resource "google_service_account" "this" {
  project      = var.project_id
  account_id   = var.account_id
  display_name = var.display_name != "" ? var.display_name : var.account_id
}
