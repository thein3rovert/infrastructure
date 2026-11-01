# ====================================
#       LXC | ALL CONTAINERS (for_each)
# ====================================
# Add a new LXC: 8-line entry in locals.tf `lxc_containers`.
# VMID doubles as the IP octet (192.168.0.<vmid>).
module "lxc" {
  source   = "../../modules/infra/providers/proxmox/lxc"
  for_each = local.lxc_containers

  target_node     = each.value.target_node
  proxmox_host_ip = each.value.proxmox_host_ip

  hostname     = each.key
  vmid         = each.value.vmid
  container_id = each.value.vmid # IP octet derives from VMID (192.168.0.<vmid>)
  os_type      = each.value.os_type

  ostemplate = each.value.ostemplate

  cores     = each.value.cores
  memory    = each.value.memory
  swap      = each.value.swap
  disk_size = each.value.disk_size
  storage   = each.value.storage

  enable_fuse = each.value.enable_fuse

  bridge      = var.bridge
  ip_base     = var.ip_base
  cidr_suffix = var.cidr_suffix
  gateway     = var.gateway

  password = local.root_password
  ssh_keys = file(var.ssh_public_key_path)

  extra_tags = each.value.extra_tags
}
