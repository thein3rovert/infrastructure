# ====================================
#       UPTIME KUMA | monitors as code
# ====================================
# Credentials come from Vault secret/uptime-kuma (username + password).
# Postgres connection string: secret/uptime-kuma key "postgres_connection_string".
# Admin login — no scoped tokens exist, so keep it in Vault, never in git.

data "vault_kv_secret_v2" "uptime_kuma" {
  mount = "secret"
  name  = "uptime-kuma"
}

locals {
  kuma_username   = data.vault_kv_secret_v2.uptime_kuma.data["username"]
  kuma_password   = data.vault_kv_secret_v2.uptime_kuma.data["password"]
  kuma_pg_conn    = data.vault_kv_secret_v2.uptime_kuma.data["postgres_connection_string"]
}

provider "uptimekuma" {
  endpoint = "https://uptime-kuma.thein3rovert.dev"
  username = local.kuma_username
  password = local.kuma_password
  timeout  = "2m"
}

module "uptimekuma" {
  source = "../../modules/uptimekuma/monitors"

  http_monitors = {
    blog = {
      url                   = "https://blog.thein3rovert.dev"
      interval              = 60
      timeout               = 48
      method                = "GET"
      accepted_status_codes = ["200-299"]
      expiry_notification   = true
      domain_expiry_notification = true
      max_retries           = 5
      retry_interval        = 20
      notification_ids      = [1]
      tags                  = [{ tag_id = 2, value = "web" }]
    }
    garage = {
      url                   = "https://s3.thein3rovert.dev"
      interval              = 60
      timeout               = 48
      method                = "GET"
      accepted_status_codes = ["400-499"]
      expiry_notification   = true
      domain_expiry_notification = true
      max_retries           = 0
      retry_interval        = 60
      notification_ids      = [1]
      tags                  = [{ tag_id = 2, value = "s3" }]
    }
  }

  ping_monitors = {
    emily = {
      hostname         = "100.105.217.77"
      interval         = 30
      timeout          = 24
      max_retries      = 0
      retry_interval   = 30
      notification_ids = [1]
      tags             = [{ tag_id = 4, value = "management" }, { tag_id = 9, value = "" }]
    }
    finn = {
      hostname         = "100.91.36.84"
      interval         = 60
      timeout          = 48
      max_retries      = 0
      retry_interval   = 60
      notification_ids = [1]
      tags             = [{ tag_id = 4, value = "" }, { tag_id = 8, value = "proxmox" }]
    }
    marcus = {
      hostname         = "100.94.20.21"
      interval         = 60
      timeout          = 48
      max_retries      = 0
      retry_interval   = 60
      notification_ids = [1]
      tags             = [{ tag_id = 4, value = "" }, { tag_id = 9, value = "" }]
    }
    lincoln = {
      hostname         = "100.87.231.18"
      interval         = 60
      timeout          = 48
      max_retries      = 0
      retry_interval   = 60
      notification_ids = [1]
      tags             = [{ tag_id = 4, value = "" }, { tag_id = 11, value = "" }]
    }
    octavia = {
      hostname         = "100.106.96.97"
      interval         = 60
      timeout          = 48
      max_retries      = 0
      retry_interval   = 60
      notification_ids = [1]
      tags             = [{ tag_id = 7, value = "incus" }, { tag_id = 4, value = "" }, { tag_id = 11, value = "" }]
    }
    github-runner = {
      hostname         = "100.87.59.51"
      interval         = 60
      timeout          = 48
      max_retries      = 0
      retry_interval   = 60
      notification_ids = []
      tags             = [{ tag_id = 4, value = "" }, { tag_id = 6, value = "" }, { tag_id = 8, value = "proxmox" }]
    }
    raven = {
      hostname         = "100.123.5.107"
      interval         = 60
      timeout          = 48
      max_retries      = 0
      retry_interval   = 60
      notification_ids = [1]
      tags             = [{ tag_id = 4, value = "" }, { tag_id = 7, value = "" }, { tag_id = 11, value = "" }]
    }
  }

  dns_monitors = {
    dns = {
      hostname                   = "ad-guard.l.thein3rovert.com"
      dns_resolve_server         = "100.91.36.84"
      dns_resolve_type           = "A"
      port                       = 53
      interval                   = 60
      domain_expiry_notification = true
      max_retries                = 0
      retry_interval             = 60
      notification_ids           = [2]
      tags                       = [{ tag_id = 1, value = "" }]
    }
  }

  tcp_monitors = {}

  postgres_monitors = {
    postgresql = {
      connection_string = local.kuma_pg_conn
      query             = "SELECT 1"
      interval          = 60
      max_retries       = 3
      retry_interval    = 60
      notification_ids  = [1]
      tags              = [{ tag_id = 2, value = "database" }]
    }
  }
}
