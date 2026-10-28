variable "http_monitors" {
  type = map(object({
    url                   = string
    interval              = optional(number, 60)
    timeout               = optional(number, 30)
    active                = optional(bool, true)
    method                = optional(string, "GET")
    accepted_status_codes = optional(list(string), ["200-299"])
    expiry_notification   = optional(bool, true)
  }))
  default     = {}
  description = "HTTP(S) monitors keyed by Terraform key (e.g. blog)."
}

variable "ping_monitors" {
  type = map(object({
    hostname = string
    interval = optional(number, 60)
    timeout  = optional(number, 30)
    active   = optional(bool, true)
  }))
  default     = {}
  description = "ICMP ping monitors keyed by Terraform key."
}

variable "dns_monitors" {
  type = map(object({
    hostname           = string
    dns_resolve_server = optional(string)
    dns_resolve_type   = optional(string, "A")
    port               = optional(number, 53)
    interval           = optional(number, 300)
    active             = optional(bool, true)
  }))
  default     = {}
  description = "DNS resolution monitors keyed by Terraform key."
}

variable "tcp_monitors" {
  type = map(object({
    hostname = string
    port     = number
    interval = optional(number, 60)
    active   = optional(bool, true)
  }))
  default     = {}
  description = "TCP port monitors keyed by Terraform key."
}
