# ====================================
#       UPTIME KUMA | monitors as code
# ====================================
# Credentials come from Vault secret/uptime-kuma (username + password).
# Admin login — no scoped tokens exist, so keep it in Vault, never in git.

data "vault_kv_secret_v2" "uptime_kuma" {
  mount = "secret"
  name  = "uptime-kuma"
}

locals {
  kuma_username = data.vault_kv_secret_v2.uptime_kuma.data["username"]
  kuma_password = data.vault_kv_secret_v2.uptime_kuma.data["password"]
}

provider "uptimekuma" {
  endpoint = "https://uptime-kuma.thein3rovert.dev"
  username = local.kuma_username
  password = local.kuma_password
}

module "uptimekuma" {
  source = "../../modules/uptimekuma/monitors"

  http_monitors = {
    # blog = {
    #   url = "https://blog.thein3rovert.dev"
    # }
  }

  ping_monitors = {}

  dns_monitors = {}

  tcp_monitors = {}
}
