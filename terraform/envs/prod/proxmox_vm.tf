# ====================================
#       VM | ALL VMS (for_each)
# ====================================
module "vm" {
  source   = "../../modules/infra/providers/proxmox/vm"
  for_each = local.proxmox_vms

  target_node    = try(each.value.target_node, var.target_node)
  hostname       = try(each.value.hostname, each.key)
  vmid           = each.value.vmid
  clone_template = each.value.clone_template

  kvm_enabled   = each.value.kvm_enabled
  agent_enabled = each.value.agent_enabled
  cores         = each.value.cores
  memory        = each.value.memory
  disk_size     = each.value.disk_size
  storage       = try(each.value.storage, var.rootfs_storage)
  data_disk     = try(each.value.data_disk, null)

  bridge      = var.bridge
  ip_address  = "${var.ip_base}.${each.value.vmid}" # IP octet derives from VMID
  cidr_suffix = var.cidr_suffix
  gateway     = var.gateway

  password   = local.root_password
  ssh_keys   = file(var.ssh_public_key_path)
  extra_tags = each.value.extra_tags

  description = each.value.description
}
