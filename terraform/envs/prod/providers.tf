# Vault provider configuration
provider "vault" {
  address = var.vault_address
  token   = var.vault_token
}

# Retrieve Proxmox credentials from Vault
data "vault_kv_secret_v2" "proxmox" {
  mount = "secret"
  name  = "proxmox"
}

# Local values for credentials from Vault
locals {
  root_password = data.vault_kv_secret_v2.proxmox.data["root_password"]

  # Format SSH keys for GCP (username:key-content for each user)
  gcp_ssh_keys = join("\n", concat(
    [
      for user in var.gcp_ssh_key_users :
      "${user}:${file(var.ssh_public_key_path)}"
    ],
    var.gcp_ssh_extra_keys,
  ))
}

# Proxmox provider using Vault secrets
provider "proxmox" {
  pm_api_url          = data.vault_kv_secret_v2.proxmox.data["pm_api_url"]
  pm_api_token_id     = data.vault_kv_secret_v2.proxmox.data["pm_api_token_id"]
  pm_api_token_secret = data.vault_kv_secret_v2.proxmox.data["pm_api_token_secret"]
  pm_tls_insecure     = true
}

# Google Cloud provider (uses GOOGLE_CREDENTIALS from environment)
provider "google" {
  region = var.gcp_region
}
