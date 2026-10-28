resource "uptimekuma_monitor_http" "this" {
  for_each = var.http_monitors

  name                       = each.key
  description                = each.value.description
  url                        = each.value.url
  interval                   = each.value.interval
  timeout                    = each.value.timeout
  active                     = each.value.active
  method                     = each.value.method
  accepted_status_codes      = each.value.accepted_status_codes
  expiry_notification        = each.value.expiry_notification
  domain_expiry_notification = each.value.domain_expiry_notification
  ignore_tls                 = each.value.ignore_tls
  oauth_auth_method          = each.value.oauth_auth_method
  max_retries                = each.value.max_retries
  retry_interval             = each.value.retry_interval
  notification_ids           = each.value.notification_ids
  tags                       = each.value.tags
}

resource "uptimekuma_monitor_ping" "this" {
  for_each = var.ping_monitors

  name             = each.key
  description      = each.value.description
  hostname         = each.value.hostname
  interval         = each.value.interval
  timeout          = each.value.timeout
  active           = each.value.active
  max_retries      = each.value.max_retries
  retry_interval   = each.value.retry_interval
  notification_ids = each.value.notification_ids
  tags             = each.value.tags
}

resource "uptimekuma_monitor_dns" "this" {
  for_each = var.dns_monitors

  name                       = each.key
  description                = each.value.description
  hostname                   = each.value.hostname
  dns_resolve_server         = each.value.dns_resolve_server
  dns_resolve_type           = each.value.dns_resolve_type
  port                       = each.value.port
  interval                   = each.value.interval
  active                     = each.value.active
  domain_expiry_notification = each.value.domain_expiry_notification
  max_retries                = each.value.max_retries
  retry_interval             = each.value.retry_interval
  notification_ids           = each.value.notification_ids
  tags                       = each.value.tags
}

resource "uptimekuma_monitor_tcp_port" "this" {
  for_each = var.tcp_monitors

  name             = each.key
  description      = each.value.description
  hostname         = each.value.hostname
  port             = each.value.port
  interval         = each.value.interval
  active           = each.value.active
  max_retries      = each.value.max_retries
  retry_interval   = each.value.retry_interval
  notification_ids = each.value.notification_ids
  tags             = each.value.tags
}

resource "uptimekuma_monitor_postgres" "this" {
  for_each = var.postgres_monitors

  name                       = each.key
  description                = each.value.description
  database_connection_string = each.value.connection_string
  database_query             = each.value.query
  interval                   = each.value.interval
  active                     = each.value.active
  max_retries                = each.value.max_retries
  retry_interval             = each.value.retry_interval
  notification_ids           = each.value.notification_ids
  tags                       = each.value.tags
}
