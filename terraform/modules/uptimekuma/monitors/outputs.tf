output "http_monitor_ids" {
  value       = { for k, r in uptimekuma_monitor_http.this : k => r.id }
  description = "HTTP monitor IDs keyed by Terraform key."
}

output "ping_monitor_ids" {
  value       = { for k, r in uptimekuma_monitor_ping.this : k => r.id }
  description = "Ping monitor IDs keyed by Terraform key."
}

output "dns_monitor_ids" {
  value       = { for k, r in uptimekuma_monitor_dns.this : k => r.id }
  description = "DNS monitor IDs keyed by Terraform key."
}

output "tcp_monitor_ids" {
  value       = { for k, r in uptimekuma_monitor_tcp_port.this : k => r.id }
  description = "TCP monitor IDs keyed by Terraform key."
}
