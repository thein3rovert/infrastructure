moved {
  from = module.nightblood_vm
  to   = module.nfs_storage
}

# Phase 2 (HML-053.02): single-module renames -> for_each
moved {
  from = module.nfs_storage
  to   = module.vm["nightblood"]
}

moved {
  from = module.homelab_vault
  to   = module.lxc["becca"]
}

moved {
  from = module.agent_knowledge_base
  to   = module.lxc["trikru"]
}

moved {
  from = module.app-container
  to   = module.lxc["roan"]
}

moved {
  from = module.dns-container["zeke"]
  to   = module.lxc["zeke"]
}

moved {
  from = module.github_runner
  to   = module.lxc["github-runner"]
}

moved {
  from = module.k3s_control_plane_01
  to   = module.vm["raven"]
}

moved {
  from = module.k3s_control_plane_02
  to   = module.vm["lincoln"]
}

moved {
  from = module.k3s_control_plane_03
  to   = module.vm["octavia"]
}

moved {
  from = module.kestra_worker_01
  to   = module.vm["indra"]
}
