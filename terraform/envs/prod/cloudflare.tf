# ====================================
#       CLOUDFLARE DNS | thein3rovert.dev
# ====================================
# Token comes from Vault secret/cloudflare:dns-token (same value as
# Traefik CF_DNS_API_TOKEN, but read here via Vault provider).

data "vault_kv_secret_v2" "cloudflare" {
  mount = "secret"
  name  = "cloudflare"
}

locals {
  cloudflare_api_token = data.vault_kv_secret_v2.cloudflare.data["dns-token"]
}

provider "cloudflare" {
  api_token = trimspace(local.cloudflare_api_token)
}

module "dns" {
  source  = "../../modules/infra/providers/cloudflare/dns"
  zone_id = var.cloudflare_zone_id

  records = {
    apex = {
      name    = "thein3rovert.dev"
      type    = "A"
      content = var.origin_ip
      proxied = false
      ttl     = 1
      comment = "apex - DNS only for cutover"
    }
    blog = {
      name    = "blog.thein3rovert.dev"
      type    = "A"
      content = var.origin_ip
      proxied = true
      ttl     = 1
      comment = "blog"
    }
    code = {
      name    = "code.thein3rovert.dev"
      type    = "A"
      content = var.origin_ip
      proxied = false
      ttl     = 1
      comment = "forgejo - DNS only (large pushes)"
    }
    freshrss = {
      name    = "freshrss.thein3rovert.dev"
      type    = "A"
      content = var.origin_ip
      proxied = true
      ttl     = 1
      comment = "freshrss"
    }
    gallery = {
      name    = "gallery.thein3rovert.dev"
      type    = "A"
      content = var.origin_ip
      proxied = true
      ttl     = 1
      comment = "gallery"
    }
    glance = {
      name    = "glance.thein3rovert.dev"
      type    = "A"
      content = var.origin_ip
      proxied = true
      ttl     = 1
      comment = "glance"
    }
    linkding = {
      name    = "linkding.thein3rovert.dev"
      type    = "A"
      content = var.origin_ip
      proxied = true
      ttl     = 1
      comment = "linkding"
    }
    memos = {
      name    = "memos.thein3rovert.dev"
      type    = "A"
      content = var.origin_ip
      proxied = true
      ttl     = 1
      comment = "memos"
    }
    minio = {
      name    = "minio.thein3rovert.dev"
      type    = "A"
      content = var.origin_ip
      proxied = false
      ttl     = 1
      comment = "minio - DNS only (S3 uploads)"
    }
    minio-console = {
      name    = "minio-console.thein3rovert.dev"
      type    = "A"
      content = var.origin_ip
      proxied = false
      ttl     = 1
      comment = "minio console - DNS only"
    }
    s3 = {
      name    = "s3.thein3rovert.dev"
      type    = "A"
      content = var.origin_ip
      proxied = false
      ttl     = 1
      comment = "s3 - DNS only (S3 uploads)"
    }
    s3-console = {
      name    = "s3-console.thein3rovert.dev"
      type    = "A"
      content = var.origin_ip
      proxied = false
      ttl     = 600
      comment = "s3 console - DNS only"
    }
    ssh = {
      name    = "ssh.thein3rovert.dev"
      type    = "A"
      content = var.origin_ip
      proxied = false
      ttl     = 1
      comment = "ssh - DNS only (proxy breaks SSH)"
    }
    uptime-kuma = {
      name    = "uptime-kuma.thein3rovert.dev"
      type    = "A"
      content = var.origin_ip
      proxied = true
      ttl     = 1
      comment = "uptime-kuma"
    }
    www = {
      name    = "www.thein3rovert.dev"
      type    = "CNAME"
      content = "thein3rovert.dev"
      proxied = true
      ttl     = 1
      comment = "www"
    }
    dmarc = {
      name    = "_dmarc.thein3rovert.dev"
      type    = "TXT"
      content = "v=DMARC1; p=reject; adkim=r; aspf=r; rua=mailto:dmarc_rua@onsecureserver.net;"
      proxied = false
      ttl     = 1
      comment = "dmarc"
    }
  }
}
