variable "http_monitors" {
  type = map(object({
    url                        = string
    interval                   = optional(number, 60)
    timeout                    = optional(number, 30)
    active                     = optional(bool, true)
    method                     = optional(string, "GET")
    accepted_status_codes      = optional(list(string), ["200-299"])
    expiry_notification        = optional(bool, false)
    domain_expiry_notification = optional(bool, false)
    max_retries                = optional(number, 0)
    retry_interval             = optional(number, 60)
    notification_ids           = optional(list(number), [])
    tags                       = optional(list(object({ tag_id = number, value = optional(string, "") })), [])
  }))
  default     = {}
  description = "HTTP(S) monitors keyed by Terraform key (e.g. blog)."
}

variable "ping_monitors" {
  type = map(object({
    hostname         = string
    interval         = optional(number, 60)
    timeout          = optional(number, 30)
    active           = optional(bool, true)
    max_retries      = optional(number, 0)
    retry_interval   = optional(number, 60)
    notification_ids = optional(list(number), [])
    tags             = optional(list(object({ tag_id = number, value = optional(string, "") })), [])
  }))
  default     = {}
  description = "ICMP ping monitors keyed by Terraform key."
}

variable "dns_monitors" {
  type = map(object({
    hostname                   = string
    dns_resolve_server         = optional(string)
    dns_resolve_type           = optional(string, "A")
    port                       = optional(number, 53)
    interval                   = optional(number, 300)
    active                     = optional(bool, true)
    domain_expiry_notification = optional(bool, false)
    max_retries                = optional(number, 0)
    retry_interval             = optional(number, 60)
    notification_ids           = optional(list(number), [])
    tags                       = optional(list(object({ tag_id = number, value = optional(string, "") })), [])
  }))
  default     = {}
  description = "DNS resolution monitors keyed by Terraform key."
}

variable "tcp_monitors" {
  type = map(object({
    hostname         = string
    port             = number
    interval         = optional(number, 60)
    active           = optional(bool, true)
    max_retries      = optional(number, 0)
    retry_interval   = optional(number, 60)
    notification_ids = optional(list(number), [])
    tags             = optional(list(object({ tag_id = number, value = optional(string, "") })), [])
  }))
  default     = {}
  description = "TCP port monitors keyed by Terraform key."
}

variable "postgres_monitors" {
  type = map(object({
    connection_string = string
    query             = optional(string, "SELECT 1")
    interval          = optional(number, 60)
    active            = optional(bool, true)
    max_retries       = optional(number, 3)
    retry_interval    = optional(number, 60)
    notification_ids  = optional(list(number), [])
    tags              = optional(list(object({ tag_id = number, value = optional(string, "") })), [])
  }))
  default     = {}
  description = "PostgreSQL monitors keyed by Terraform key. Connection string is sensitive — pass from Vault, never inline."
}
