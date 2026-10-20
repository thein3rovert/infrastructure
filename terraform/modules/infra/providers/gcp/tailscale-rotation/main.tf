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
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region for the Run job and Scheduler"
}

variable "secret_id" {
  type        = string
  description = "Existing Secret Manager secret holding the Tailscale key"
}

variable "enable_schedule" {
  type        = bool
  description = "Create and unpause the Scheduler trigger (default off; enable after dry-run validation)"
  default     = false
}

variable "schedule_cron" {
  type        = string
  description = "Schedule for expiry checks (UTC)"
  default     = "0 6 * * 1" # weekly Monday 06:00
}

variable "job_image" {
  type        = string
  description = "Container image for the rotation job"
}

variable "tailnet" {
  type        = string
  description = "Tailscale tailnet (org/team name)"
}

variable "rotation_threshold_days" {
  type        = number
  description = "Rotate when fewer days remain"
  default     = 14
}

variable "key_ttl_seconds" {
  type        = number
  description = "Lifetime of replacement keys"
  default     = 7776000
}

variable "dry_run" {
  type        = bool
  description = "Start in dry-run mode (no keys created)"
  default     = true
}

variable "labels" {
  type        = map(string)
  description = "Labels for created resources"
  default     = {}
}

# Least-privilege service account: read/update the one secret only.
resource "google_service_account" "rotation" {
  project      = var.project_id
  account_id   = "tailscale-key-rotation"
  display_name = "Tailscale key rotation (least privilege)"
}

resource "google_secret_manager_secret_iam_member" "viewer" {
  project   = var.project_id
  secret_id = var.secret_id
  role      = "roles/secretmanager.viewer"
  member    = "serviceAccount:${google_service_account.rotation.email}"
}

resource "google_secret_manager_secret_iam_member" "version_manager" {
  project   = var.project_id
  secret_id = var.secret_id
  role      = "roles/secretmanager.secretVersionManager"
  member    = "serviceAccount:${google_service_account.rotation.email}"
}

resource "google_cloud_run_v2_job" "rotation" {
  project  = var.project_id
  location = var.region
  name     = "tailscale-key-rotation"
  labels   = var.labels

  template {
    template {
      service_account = google_service_account.rotation.email
      containers {
        image = var.job_image
        env {
          name  = "GCP_PROJECT"
          value = var.project_id
        }
        env {
          name  = "SECRET_ID"
          value = var.secret_id
        }
        env {
          name  = "TAILNET"
          value = var.tailnet
        }
        env {
          name  = "ROTATION_THRESHOLD_DAYS"
          value = tostring(var.rotation_threshold_days)
        }
        env {
          name  = "KEY_TTL_SECONDS"
          value = tostring(var.key_ttl_seconds)
        }
        env {
          name  = "DRY_RUN"
          value = tostring(var.dry_run)
        }
        env {
          name  = "REVOKE_PREVIOUS"
          value = "false" # never auto-revoke without separate review
        }
      }
    }
  }
}

resource "google_cloud_scheduler_job" "rotation" {
  count       = var.enable_schedule ? 1 : 0
  project     = var.project_id
  region      = var.region
  name        = "tailscale-key-rotation"
  description = "Weekly Tailscale auth-key expiry check"
  schedule    = var.schedule_cron
  time_zone   = "Etc/UTC"
  paused      = true # unpause explicitly after dry-run validation

  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/${google_cloud_run_v2_job.rotation.id}:run"
    oauth_token {
      service_account_email = google_service_account.rotation.email
    }
  }
}

output "service_account_email" {
  value       = google_service_account.rotation.email
  description = "Least-privilege SA for the rotation job"
}

output "job_name" {
  value       = google_cloud_run_v2_job.rotation.name
  description = "Cloud Run job name"
}
