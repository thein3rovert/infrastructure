variable "zone_id" {
  type        = string
  description = "Cloudflare zone ID for thein3rovert.dev."
}

variable "records" {
  type = map(object({
    name    = string
    type    = string
    content = string
    proxied = bool
    ttl     = number
    comment = optional(string, "")
  }))
  description = "DNS records keyed by Terraform key (e.g. apex, blog, www)."
}
