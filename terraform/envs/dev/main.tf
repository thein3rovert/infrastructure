terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc07"
    }
    incus = {
      source  = "lxc/incus"
      version = "~> 0.1"
    }
  }
}

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
}

# Proxmox provider using Vault secrets
provider "proxmox" {
  pm_api_url          = data.vault_kv_secret_v2.proxmox.data["pm_api_url"]
  pm_api_token_id     = data.vault_kv_secret_v2.proxmox.data["pm_api_token_id"]
  pm_api_token_secret = data.vault_kv_secret_v2.proxmox.data["pm_api_token_secret"]
  pm_tls_insecure     = true
}

# Incus provider configuration
provider "incus" {
  generate_client_certificates = false
  accept_remote_certificate    = true

  remote {
    name    = "marcus"
    scheme  = "https"
    address = "100.94.20.21"
    port    = "8443"
  }
}
# ====================================
#       VM | KUBERNETES | INCUS
# ====================================

# Ubuntu VM on Incus (marcus server)
# TODO: Remove Control Plane on Marcus (incus) and move to
# cluster
module "incus_ubuntu_vm" {
  source = "../../modules/infra/providers/incus/vm"

  vm_name   = "k3s-server"
  image     = "images:ubuntu/24.04/cloud"
  cpu_cores = 4
  memory_mb = 4096
  disk_size = "30GB"
  ssh_keys  = [file(var.ssh_public_key_path)]

  # Static IP configuration for k3s
  static_ip   = "10.10.20.100"
  gateway     = "10.10.20.1"
  dns_servers = ["8.8.8.8", "8.8.4.4"]
}

# ====================================
#       LOCALS | DYNAMIC IP OUTPUTS
# ====================================

locals {
  # Use static IP for k3s (since we configured it in cloud-init)
  control_plane_ips              = ["10.10.20.100"]
  worker_ips                     = []
  kube_api_loadbalancer_dns_name = var.kube_api_loadbalancer_dns_name
  kube_vip_address               = "10.10.20.100"

  # K3s always needs bastion since it connects to internal IP
  # Rancher can use Tailscale IP directly if available
  rancher_access_ip       = var.tailscale_ip != null ? var.tailscale_ip : "10.10.20.100"
  use_bastion_for_rancher = var.tailscale_ip == null
}

# ====================================
#       K3S | KUBERNETES | INCUS
# ====================================

# Wait for cloud-init to complete before installing k3s
resource "time_sleep" "wait_for_cloud_init" {
  depends_on = [module.incus_ubuntu_vm]

  create_duration = "60s"
}

# Install k3s on the Incus Ubuntu VM
module "k3s_incus" {
  source = "../../modules/container/kubernetes/k3s"

  control_plane_ips              = local.control_plane_ips
  worker_ips                     = local.worker_ips
  ssh_user                       = var.ssh_user
  ssh_pub_key_file_path          = var.ssh_private_key_path
  kube_api_loadbalancer_dns_name = local.kube_api_loadbalancer_dns_name
  kube_vip_address               = local.kube_vip_address
  kube_vip_enable                = var.kube_vip_enable
  tailscale_ip                   = var.tailscale_ip

  # Bastion host configuration to reach VM on internal network (always needed for k3s)
  bastion_host = "100.94.20.21"
  bastion_user = "root"
  bastion_port = 22

  depends_on = [time_sleep.wait_for_cloud_init]
}

# ====================================
#       RANCHER | KUBERNETES MGMT
# ====================================

# Install Rancher for managing k8s clusters
# NOTE: Rancher commented out - too resource intensive for dev setup
# Use k9s or kubectl for cluster management instead
# module "rancher" {
#   source = "../../modules/apps/rancher"
#
#   control_plane_ips     = [local.rancher_access_ip]
#   ssh_user              = var.ssh_user
#   ssh_private_key_path  = var.ssh_private_key_path
#
#   rancher_hostname            = "rancher.local"
#   rancher_bootstrap_password  = "admin"
#
#   # Bastion host configuration (only if Tailscale not available for Rancher)
#   bastion_host = local.use_bastion_for_rancher ? "100.94.20.21" : null
#   bastion_user = "root"
#   bastion_port = 22
#
#   depends_on = [module.k3s_incus]
# }
