# ====================================
#       SHARED INVENTORY (prod)
# ====================================
# VMID doubles as the IP octet (192.168.0.<vmid>).
# VMIDs in use: 51 finn, 101 becca, 102 trikru, 103 roan, 105 nightblood,
#               106 zeke, 111 raven, 112 lincoln, 114 indra, 120 github-runner.
# Free: 104, 107, 108, 109, 110, 113 ...
locals {
  nixos_lxc_template = "local:vztmpl/nixos-image-lxc-proxmox-26.05.20251205.f61125a-x86_64-linux.tar.xz"

  lxc_containers = {
    becca = {
      vmid            = 101
      container_id    = 101
      os_type         = "ubuntu"
      ostemplate      = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
      cores           = 1
      memory          = 1024
      swap            = 512
      disk_size       = "3G"
      storage         = var.rootfs_storage
      target_node     = var.target_node
      proxmox_host_ip = var.proxmox_host_ip
      extra_tags      = ["vault"]
      enable_fuse     = false
    }
    trikru = {
      vmid            = 102
      container_id    = 102
      os_type         = "ubuntu"
      ostemplate      = var.ostemplate
      cores           = 2
      memory          = 2048
      swap            = 512
      disk_size       = "20G"
      storage         = "LVM_MAIN"
      target_node     = var.target_node
      proxmox_host_ip = var.proxmox_host_ip
      extra_tags      = ["obsidian", "knowledge-base"]
      enable_fuse     = false
    }
    roan = {
      vmid            = 103
      container_id    = 103
      os_type         = "nixos"
      ostemplate      = local.nixos_lxc_template
      cores           = 2
      memory          = 2048
      swap            = 1024
      disk_size       = "20G"
      storage         = var.rootfs_storage
      target_node     = var.proxmox_placements["app_container"]
      proxmox_host_ip = var.proxmox_nodes[var.proxmox_placements["app_container"]].host_ip
      extra_tags      = ["apps", "podman"]
      enable_fuse     = true
    }
    zeke = {
      vmid            = 106
      container_id    = 106
      os_type         = "nixos"
      ostemplate      = local.nixos_lxc_template
      cores           = 1
      memory          = 1024
      swap            = 512
      disk_size       = "10G"
      storage         = "local-lvm"
      target_node     = "mount-weather"
      proxmox_host_ip = var.proxmox_nodes["mount-weather"].host_ip
      extra_tags      = ["dns", "podman"]
      enable_fuse     = false
    }
    github-runner = {
      vmid            = 120
      container_id    = 120
      os_type         = "ubuntu"
      ostemplate      = var.ostemplate
      cores           = 2
      memory          = 4096
      swap            = 2048
      disk_size       = "100G"
      storage         = "LVM_MAIN"
      target_node     = var.target_node
      proxmox_host_ip = var.proxmox_host_ip
      extra_tags      = ["github-runner", "ci"]
      enable_fuse     = false
    }
  }

  proxmox_vms = {
    raven = {
      vmid           = 111
      clone_template = "ubuntu-22.04-cloud"
      kvm_enabled    = true
      agent_enabled  = true
      cores          = 2
      memory         = 4096
      disk_size      = "30G"
      storage        = var.rootfs_storage
      target_node    = var.target_node
      ip_address     = "${var.ip_base}.111"
      extra_tags     = ["k3s", "ubuntu"]
      description    = "k3s Server Control Plane"
      data_disk      = null
    }
    lincoln = {
      vmid           = 112
      clone_template = "ubuntu-22.04-cloud"
      kvm_enabled    = true
      agent_enabled  = true
      cores          = 2
      memory         = 4096
      disk_size      = "30G"
      storage        = var.rootfs_storage
      target_node    = var.target_node
      ip_address     = "${var.ip_base}.112"
      extra_tags     = ["k3s", "ubuntu"]
      description    = "k3s Server Control Plane"
      data_disk      = null
    }
    octavia = {
      vmid           = 113
      clone_template = "ubuntu-22.04-cloud"
      kvm_enabled    = true
      agent_enabled  = true
      cores          = 2
      memory         = 4096
      disk_size      = "30G"
      storage        = var.rootfs_storage
      target_node    = var.target_node
      ip_address     = "${var.ip_base}.113"
      extra_tags     = ["k3s", "ubuntu"]
      description    = "k3s Server Control Plane - replacement for marcus incus VM (HML-045)\nNOTE: ubuntu-22.04-cloud template must exist on mount-weather (currently only on thein3rovert) - copy before apply"
      data_disk      = null
    }
    indra = {
      vmid           = 114
      clone_template = "ubuntu-22.04-cloud"
      kvm_enabled    = true
      agent_enabled  = true
      cores          = 2
      memory         = 4096
      disk_size      = "20G"
      storage        = var.rootfs_storage
      target_node    = var.target_node
      ip_address     = "${var.ip_base}.114"
      extra_tags     = ["kestra", "worker", "docker"]
      description    = "Kestra persistent worker with Docker for ephemeral CI jobs"
      data_disk      = null
    }
    nightblood = {
      vmid           = 105
      clone_template = "ubuntu-cloud-template"
      kvm_enabled    = false
      agent_enabled  = false
      cores          = 1
      memory         = 1024
      disk_size      = "8G"
      storage        = var.rootfs_storage
      target_node    = var.proxmox_placements["nfs_storage"]
      ip_address     = "${var.ip_base}.105"
      extra_tags     = ["nfs", "storage", "ubuntu"]
      description    = "Ubuntu NFS storage VM"
      data_disk = {
        size    = "100G"
        storage = "LVM_MAIN"
      }
    }
  }
}
