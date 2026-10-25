output "record_ids" {
  value       = { for k, r in cloudflare_dns_record.this : k => r.id }
  description = "Cloudflare record IDs keyed by Terraform key."
}
