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
