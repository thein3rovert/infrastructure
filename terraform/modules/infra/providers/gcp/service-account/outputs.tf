output "email" {
  value       = google_service_account.this.email
  description = "Service account email address"
}

output "name" {
  value       = google_service_account.this.name
  description = "Fully qualified service account resource name"
}

output "unique_id" {
  value       = google_service_account.this.unique_id
  description = "Numeric service account ID"
}
