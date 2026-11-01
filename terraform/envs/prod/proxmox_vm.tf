# ====================================
#       VM | ALL VMS (for_each)
# ====================================
module "vm" {
  source   = "../../modules/infra/providers/proxmox/vm"
  for_each = local.proxmox_vms

  target_node    = each.value.target_node
  hostname       = each.key
  vmid           = each.value.vmid
  clone_template = each.value.clone_template

  kvm_enabled   = each.value.kvm_enabled
  agent_enabled = each.value.agent_enabled
  cores         = each.value.cores
  memory        = each.value.memory
  disk_size     = each.value.disk_size
  storage       = each.value.storage
  data_disk     = each.value.data_disk

  bridge      = var.bridge
  ip_address  = each.value.ip_address
  cidr_suffix = var.cidr_suffix
  gateway     = var.gateway

  password   = local.root_password
  ssh_keys   = file(var.ssh_public_key_path)
  extra_tags = each.value.extra_tags

  description = each.value.description
}
