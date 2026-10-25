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
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
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

# ====================================
#       LXC | HASHICORP VAULT [BECCA]
# ====================================
module "homelab_vault" {
  source = "../../modules/infra/providers/proxmox/lxc"

  # -- Identity
  hostname = "becca"
  vmid     = 101
  os_type  = "ubuntu"

  # -- Template
  ostemplate = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"

  # -- Resources
  cores     = 1
  memory    = 1024
  disk_size = "3G"
  storage   = var.rootfs_storage

  # -- Network
  ip_base         = var.ip_base
  cidr_suffix     = var.cidr_suffix
  gateway         = var.gateway
  bridge          = var.bridge
  proxmox_host_ip = var.proxmox_host_ip

  # -- Auth
  password = local.root_password
  ssh_keys = file(var.ssh_public_key_path)

  # -- Proxmox
  target_node  = var.target_node
  container_id = 101

  # -- Tags
  extra_tags = ["vault"]
}


# 🖥️ trikru — AI Agent VM
# ━━━━━━━━━━━━━━━━━━━━━━━━
# 📦 Stack: OpenClaw (AI agent gateway) | Ubuntu 22.04 LTS
# ⚙️ Specs: 2 vCPU | 2GB RAM | 20GB Disk
# 🌐 Network: 10.10.10.102/24
# 🏷️ Tags: ai | openclaw | terraform | ubuntu
# 📝 Notes: QEMU Guest Agent enabled | Named after the Trikru clan (The 100)

# module "trikru_vm" {
#   source = "../../modules/infra/providers/proxmox/vm"
#
#   target_node    = var.target_node
#   hostname       = "trikru"
#   vmid           = 102
#   clone_template = "ubuntu-22.04-cloud"
#
#   kvm_enabled   = true # KVM now available after BIOS update
#   agent_enabled = true # QEMU guest agent installed
#   cores         = 2
#   memory        = 4096
#   disk_size     = "20G"
#   storage       = var.rootfs_storage
#
#   bridge      = var.bridge
#   ip_address  = "${var.ip_base}.102"
#   cidr_suffix = var.cidr_suffix
#   gateway     = var.gateway
#
#   password   = local.root_password
#   ssh_keys   = file(var.ssh_public_key_path)
#   extra_tags = ["ai", "openclaw", "ubuntu"]
#
#   description = <<-EOT
#     🖥️ trikru — AI Agent VM
#     ━━━━━━━━━━━━━━━━━━━━━━━━
#     📦 Stack
#        • OpenClaw (AI agent gateway)
#        • Ubuntu 22.04 LTS (Jammy)
#     ⚙️ Specs
#        • 2 vCPU | 2GB RAM | 20GB Disk
#        • Node: thein3rovert
#     🌐 Network
#        • IP: 10.10.10.102/24
#        • Interface: eth0
#     🏷️ Tags: ai | openclaw | terraform | ubuntu
#     📝 Notes
#        • Managed by Terraform
#        • QEMU Guest Agent: enabled
#        • Named after the Trikru clan (The 100)
#   EOT
# }

module "k3s_control_plane_01" {
  source = "../../modules/infra/providers/proxmox/vm"

  target_node    = var.target_node
  hostname       = "Raven"
  vmid           = 111
  clone_template = "ubuntu-22.04-cloud"

  kvm_enabled   = true # KVM now available after BIOS update
  agent_enabled = true # QEMU guest agent installed
  cores         = 2
  memory        = 4096
  disk_size     = "30G"
  storage       = var.rootfs_storage

  bridge      = var.bridge
  ip_address  = "${var.ip_base}.111"
  cidr_suffix = var.cidr_suffix
  gateway     = var.gateway

  password   = local.root_password
  ssh_keys   = file(var.ssh_public_key_path)
  extra_tags = ["k3s", "ubuntu"]

  description = <<-EOT
    k3s Server Control Plane
  EOT
}

module "k3s_control_plane_02" {
  source = "../../modules/infra/providers/proxmox/vm"

  target_node    = var.target_node
  hostname       = "lincoln"
  vmid           = 112
  clone_template = "ubuntu-22.04-cloud"

  kvm_enabled   = true # KVM now available after BIOS update
  agent_enabled = true # QEMU guest agent installed
  cores         = 2
  memory        = 4096
  disk_size     = "30G"
  storage       = var.rootfs_storage

  bridge      = var.bridge
  ip_address  = "${var.ip_base}.112"
  cidr_suffix = var.cidr_suffix
  gateway     = var.gateway

  password   = local.root_password
  ssh_keys   = file(var.ssh_public_key_path)
  extra_tags = ["k3s", "ubuntu"]

  description = <<-EOT
    k3s Server Control Plane
  EOT
}

module "k3s_control_plane_03" {
  source = "../../modules/infra/providers/proxmox/vm"

  target_node    = var.target_node
  hostname       = "octavia"
  vmid           = 113
  clone_template = "ubuntu-22.04-cloud"

  kvm_enabled   = true
  agent_enabled = true
  cores         = 2
  memory        = 4096
  disk_size     = "30G"
  storage       = var.rootfs_storage

  bridge      = var.bridge
  ip_address  = "${var.ip_base}.113"
  cidr_suffix = var.cidr_suffix
  gateway     = var.gateway

  password   = local.root_password
  ssh_keys   = file(var.ssh_public_key_path)
  extra_tags = ["k3s", "ubuntu"]

  description = <<-EOT
    k3s Server Control Plane - replacement for marcus incus VM (HML-045)
    NOTE: ubuntu-22.04-cloud template must exist on mount-weather (currently only on thein3rovert) - copy before apply
  EOT
}

module "kestra_worker_01" {
  source = "../../modules/infra/providers/proxmox/vm"

  target_node    = var.target_node
  hostname       = "indra"
  vmid           = 114
  clone_template = "ubuntu-22.04-cloud"

  kvm_enabled   = true
  agent_enabled = true
  cores         = 2
  memory        = 4096
  disk_size     = "20G"
  storage       = var.rootfs_storage

  bridge      = var.bridge
  ip_address  = "${var.ip_base}.114"
  cidr_suffix = var.cidr_suffix
  gateway     = var.gateway

  password   = local.root_password
  ssh_keys   = file(var.ssh_public_key_path)
  extra_tags = ["kestra", "worker", "docker"]

  description = "Kestra persistent worker with Docker for ephemeral CI jobs"
}


# ====================================
#       LXC | GITHUB-RUNNER
# ====================================

module "github_runner" {
  source = "../../modules/infra/providers/proxmox/lxc"

  target_node = var.target_node
  password    = local.root_password
  hostname    = "github-runner"
  vmid        = 120
  ostemplate  = var.ostemplate
  cores       = 2
  memory      = 4096
  # Due to 00M Hang during peaK nixos build
  # i am upgarding the swap to 2gb
  swap      = 2048
  disk_size = "100G"
  storage   = "LVM_MAIN" # Use the 1TB HDD instead of LVM thin pool

  bridge          = var.bridge
  ip_base         = var.ip_base
  cidr_suffix     = var.cidr_suffix
  gateway         = var.gateway
  proxmox_host_ip = var.proxmox_host_ip

  ssh_keys = file(var.ssh_public_key_path)

  container_id = 120
  os_type      = "ubuntu"
  extra_tags   = ["github-runner", "ci"]
}

# ====================================
#       LXC | NIXOS APPLICATIONS
# ====================================

module "app-container" {
  source = "../../modules/infra/providers/proxmox/lxc"

  # Select placement from the reusable Proxmox cluster node inventory.
  target_node     = var.proxmox_placements["app_container"]
  proxmox_host_ip = var.proxmox_nodes[var.proxmox_placements["app_container"]].host_ip

  # -- Identity
  hostname     = "roan"
  vmid         = 103
  container_id = 103
  os_type      = "nixos"

  # -- NixOS Proxmox LXC template uploaded to local CT template storage
  ostemplate = "local:vztmpl/nixos-image-lxc-proxmox-26.05.20251205.f61125a-x86_64-linux.tar.xz"

  # -- Resources
  cores       = 2
  memory      = 2048
  swap        = 1024
  disk_size   = "20G"
  storage     = var.rootfs_storage
  enable_fuse = true

  # -- Network
  bridge      = var.bridge
  ip_base     = var.ip_base
  cidr_suffix = var.cidr_suffix
  gateway     = var.gateway

  # -- Auth
  password = local.root_password
  ssh_keys = file(var.ssh_public_key_path)

  extra_tags = ["apps", "podman"]
}

# ====================================
#       LXC | TECHNITIUM DNS
# ====================================
#
# N dedicated DNS resolvers, one instance each via `for_each`.
# To scale, add/remove entries below — the VMID doubles as the IP octet
# (192.168.0.<vmid>) so every resolver gets a unique, stable IP.
#
# VMIDs in use: 51 finn, 101 becca, 102 trikru, 103 roan, 105 nightblood,
#               111 raven, 112 lincoln, 120 github-runner.
# Free: 104, 106, 107, 108, 109, 110, 113, 114 ...
locals {
  # Each resolver maps to a Proxmox node; VMID = IP octet (192.168.0.<vmid>).
  # `storage` + `ostemplate` are per-node since pool names and available
  # templates can differ across hosts (each node needs the template in its
  # own `local` storage).
  dns_containers = {
    zeke = {
      vmid       = 106
      node       = "mount-weather"
      storage    = "local-lvm"
      ostemplate = "local:vztmpl/nixos-image-lxc-proxmox-26.05.20251205.f61125a-x86_64-linux.tar.xz"
    }
    # <name2> = {
    #   vmid       = 106
    #   node       = "thein3rovert"
    #   storage    = "local-lvm"
    #   ostemplate = "local:vztmpl/nixos-image-lxc-proxmox-26.05.20251205.f61125a-x86_64-linux.tar.xz"
    # }
    # <name3> = {
    #   vmid       = 107
    #   node       = "<third-node>" # add to proxmox_nodes in terraform.tfvars later
    #   storage    = "<third-node-pool>"
    #   ostemplate = "<third-node-template>"
    # }
  }
}

module "dns-container" {
  source   = "../../modules/infra/providers/proxmox/lxc"
  for_each = local.dns_containers

  # Placement is per-instance: each resolver runs on its own Proxmox node.
  target_node     = each.value.node
  proxmox_host_ip = var.proxmox_nodes[each.value.node].host_ip

  # -- Identity
  hostname     = each.key
  vmid         = each.value.vmid
  container_id = each.value.vmid
  os_type      = "nixos"

  # -- NixOS Proxmox LXC template uploaded to local CT template storage
  ostemplate = each.value.ostemplate

  # -- Resources (DNS is lightweight; headroom for .NET runtime)
  cores     = 1
  memory    = 1024
  swap      = 512
  disk_size = "10G"
  storage   = each.value.storage

  # NOTE: feature flags fuse/keyctl/mount/mknod require root@pam (API tokens
  # can only toggle `nesting`). DNS doesn't need FUSE, so it's left off.
  # enable_fuse = true

  # -- Network (IP derived from container_id -> 192.168.0.<vmid>)
  bridge      = var.bridge
  ip_base     = var.ip_base
  cidr_suffix = var.cidr_suffix
  gateway     = var.gateway

  # -- Auth
  password = local.root_password
  ssh_keys = file(var.ssh_public_key_path)

  extra_tags = ["dns", "podman"]
}

# ====================================
#       VM | UBUNTU NFS STORAGE
# ====================================

moved {
  from = module.nightblood_vm
  to   = module.nfs_storage
}

module "nfs_storage" {
  source = "../../modules/infra/providers/proxmox/vm"

  target_node    = var.proxmox_placements["nfs_storage"]
  hostname       = "nightblood"
  vmid           = 105
  clone_template = "ubuntu-cloud-template"

  kvm_enabled   = true
  agent_enabled = true
  cores         = 1
  memory        = 1024
  disk_size     = "8G"
  storage       = var.rootfs_storage

  data_disk = {
    size    = "100G"
    storage = "LVM_MAIN"
  }

  bridge      = var.bridge
  ip_address  = "${var.ip_base}.105"
  cidr_suffix = var.cidr_suffix
  gateway     = var.gateway

  password = local.root_password
  ssh_keys = file(var.ssh_public_key_path)

  extra_tags  = ["nfs", "storage", "ubuntu"]
  description = "Ubuntu NFS storage VM"
}

# ====================================
#  LXC | OBSIDIAN AS KNOWLEDHE BASE
# ====================================

module "agent_knowledge_base" {
  source = "../../modules/infra/providers/proxmox/lxc"

  target_node = var.target_node
  password    = local.root_password
  hostname    = "trikru"
  vmid        = 102
  ostemplate  = var.ostemplate
  cores       = 2
  memory      = 2048
  swap        = 512
  disk_size   = "20G"
  storage     = "LVM_MAIN" # Use the 1TB HDD instead of LVM thin pool

  bridge          = var.bridge
  ip_base         = var.ip_base
  cidr_suffix     = var.cidr_suffix
  gateway         = var.gateway
  proxmox_host_ip = var.proxmox_host_ip

  ssh_keys = file(var.ssh_public_key_path)

  container_id = 102
  os_type      = "ubuntu"
  extra_tags   = ["obsidian", "knowledge-base"]
}

# ====================================
#       GCP | VM INSTANCE
# ====================================

module "gcp_vm" {
  source = "../../modules/infra/providers/gcp/vm"

  # Required
  project_id    = var.gcp_project_id
  zone          = var.gcp_zone
  instance_name = var.gcp_instance_name

  # Machine config
  machine_type = var.gcp_machine_type

  # Disk config
  boot_disk_image = var.gcp_boot_disk_image
  boot_disk_size  = var.gcp_boot_disk_size
  boot_disk_type  = var.gcp_boot_disk_type

  # Network config
  network            = var.gcp_network
  enable_external_ip = var.gcp_enable_external_ip

  # SSH access
  ssh_keys = local.gcp_ssh_keys

  # Tags and labels
  tags   = var.gcp_tags
  labels = var.gcp_labels

  # Optional startup script
  startup_script = var.gcp_startup_script
}

# ====================================
#       GCP | SECRET MANAGER
# ====================================

module "tailscale_secret" {
  source = "../../modules/infra/providers/gcp/secret-manager"

  project_id  = var.gcp_project_id
  secret_id   = "tailscale-authkey"
  secret_data = var.tailscale_authkey

  labels = {
    environment = "production"
    managed_by  = "terraform"
    service     = "tailscale"
  }
}

# Tailscale key rotation identity: generic service account plus the two
# Secret Manager grants it needs on tailscale-authkey and nothing else.
module "tailscale_rotation_sa" {
  source = "../../modules/infra/providers/gcp/service-account"

  project_id   = var.gcp_project_id
  account_id   = "tailscale-key-rotation"
  display_name = "Tailscale key rotation (least privilege)"
}

resource "google_secret_manager_secret_iam_member" "tailscale_rotation_viewer" {
  project   = var.gcp_project_id
  secret_id = "tailscale-authkey"
  role      = "roles/secretmanager.viewer"
  member    = "serviceAccount:${module.tailscale_rotation_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "tailscale_rotation_version_manager" {
  project   = var.gcp_project_id
  secret_id = "tailscale-authkey"
  role      = "roles/secretmanager.secretVersionManager"
  member    = "serviceAccount:${module.tailscale_rotation_sa.email}"
}

# ====================================
#       GCP | STORAGE BUCKET (Infrastructure)
# ====================================

module "infra_bucket" {
  source = "../../modules/infra/providers/gcp/storage-bucket"

  project_id         = var.gcp_project_id
  bucket_name        = var.gcp_infra_bucket_name
  location           = "us-central1" # Always Free eligible (regional, not multi-region)
  storage_class      = "STANDARD"
  versioning_enabled = true
  force_destroy      = false # Protect from accidental deletion

  labels = {
    purpose     = "infrastructure"
    environment = "production"
    region      = "us"
    managed_by  = "terraform"
  }
}
