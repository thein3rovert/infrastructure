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
