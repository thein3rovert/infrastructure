resource "uptimekuma_monitor_http" "this" {
  for_each = var.http_monitors

  name                  = each.key
  url                   = each.value.url
  interval              = each.value.interval
  timeout               = each.value.timeout
  active                = each.value.active
  method                = each.value.method
  accepted_status_codes = each.value.accepted_status_codes
  expiry_notification   = each.value.expiry_notification
}

resource "uptimekuma_monitor_ping" "this" {
  for_each = var.ping_monitors

  name     = each.key
  hostname = each.value.hostname
  interval = each.value.interval
  timeout  = each.value.timeout
  active   = each.value.active
}

resource "uptimekuma_monitor_dns" "this" {
  for_each = var.dns_monitors

  name               = each.key
  hostname           = each.value.hostname
  dns_resolve_server = each.value.dns_resolve_server
  dns_resolve_type   = each.value.dns_resolve_type
  port               = each.value.port
  interval           = each.value.interval
  active             = each.value.active
}

resource "uptimekuma_monitor_tcp_port" "this" {
  for_each = var.tcp_monitors

  name     = each.key
  hostname = each.value.hostname
  port     = each.value.port
  interval = each.value.interval
  active   = each.value.active
}
