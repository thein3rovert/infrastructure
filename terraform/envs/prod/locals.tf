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
