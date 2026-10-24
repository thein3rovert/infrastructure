
#========= Proxmox Configuration =================
variable "target_node" {
  type        = string
  description = "The name of the target Proxmox node."
  default     = "thein3rovert"
}

variable "proxmox_host_ip" {
  type        = string
  description = "The IP address of the Proxmox host for the CI provisioner."
  default     = "192.168.0.50"
}

variable "proxmox_nodes" {
  type = map(object({
    host_ip = string
  }))
  description = "Reusable inventory of Proxmox cluster nodes keyed by node name."
}

variable "proxmox_placements" {
  type        = map(string)
  description = "Proxmox node assignment for each workload, keyed by workload name."

  validation {
    condition     = alltrue([for node in values(var.proxmox_placements) : contains(keys(var.proxmox_nodes), node)])
    error_message = "Every proxmox_placements value must match a key in proxmox_nodes."
  }
}

variable "hostname" {
  type        = string
  description = "The hostname for the new LXC container."
  default     = "thein3rovert-iac"
}
variable "rootfs_storage" {
  type        = string
  description = "The storage pool for the container's root disk (e.g., local-lvm)."
  default     = "local-lvm"
}

#========= Networking Configuration =================

variable "bridge" { default = "vmbr0" }

variable "container_id" {
  type        = number
  description = "The ID for the LXC container. If null, Proxmox will assign the next available ID."
  default     = "100"
  validation {
    condition     = var.ip_base == null || (var.ip_base != null && var.container_id != null)
    error_message = "If you specify an 'ip_prefix', you must also specify a 'container_id'."
  }
}

variable "ip_base" {
  type        = string
  description = "The IP prefix for a static IP (e.g., '10.20.0'), setting a container_id is required for this. If null, DHCP will be used."
  default     = "192.168.0"
}

variable "cidr_suffix" {
  type        = string
  description = "The CIDR suffix for the network (e.g., '24' for /24)."
  default     = "24"
}

variable "gateway" {
  type        = string
  description = "The network gateway IP address. Required for static IP configuration. (e.g., 10.10.20.1)"
  default     = "192.168.0.1"
}

variable "ssh_public_key_path" {
  type        = string
  description = "The path to the public SSH key to install in the container."
  default     = "~/.ssh/id_ed25519.pub"
}

variable "extra_tags" {
  description = "Additional tags to add to the container."
  type        = list(string)
  default     = ["prod"]
}

#=========== Vault variables===============

variable "vault_address" {
  type        = string
  description = "The address of the Vault server."
  default     = "http://100.92.136.66:8200"
}

variable "vault_token" {
  type        = string
  description = "The token to authenticate with Vault."
  sensitive   = true
}

variable "ostemplate" {
  type        = string
  description = "The name of the LXC template to use (e.g., 'local:vztmpl/alpine-3.22-default_20250617_amd64.tar.xz')."
  default     = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
  # default     = "local:vztmpl/alpine-3.22-default_20250617_amd64.tar.xz"
}



# Create local for gateway and ip-prefix
#   locals {
#   ip_prefix = "${var.ip_base}/${var.cidr_suffix}"
# }
# locals {
#   gateway = cidrhost(var.ip_prefix, 1)
# }



# variable "ostemplate" {
#   type        = string
#   description = "The name of the LXC template to use."
#   default     = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
#   validation {
#     condition     = contains([
#       "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst",
#       "local:vztmpl/alpine-3.22-default_20250617_amd64.tar.xz"
#     ], var.ostemplate)
#     error_message = "ostemplate must be either Ubuntu 22.04 or Alpine 3.22."
#   }
# }

#========= GCP Configuration =================

variable "gcp_project_id" {
  type        = string
  description = "GCP project ID"
}

variable "gcp_region" {
  type        = string
  description = "Default GCP region"
  default     = "us-central1"
}

variable "gcp_zone" {
  type        = string
  description = "GCP zone"
  default     = "us-central1-a"
}

variable "gcp_instance_name" {
  type        = string
  description = "Name of the GCP VM instance"
  default     = "prod-vm-01"
}

variable "gcp_machine_type" {
  type        = string
  description = "GCP machine type"
  default     = "e2-medium"
}

variable "gcp_boot_disk_image" {
  type        = string
  description = "Boot disk image"
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "gcp_boot_disk_size" {
  type        = number
  description = "Boot disk size in GB"
  default     = 20
}

variable "gcp_boot_disk_type" {
  type        = string
  description = "Boot disk type"
  default     = "pd-balanced"
}

variable "gcp_network" {
  type        = string
  description = "VPC network"
  default     = "default"
}

variable "gcp_enable_external_ip" {
  type        = bool
  description = "Assign external IP"
  default     = true
}

variable "gcp_ssh_keys" {
  type        = string
  description = "SSH public keys (format: username:ssh-rsa AAAAB3...)"
  default     = ""
}

variable "gcp_ssh_key_users" {
  type        = list(string)
  description = "List of usernames to create with SSH access"
  default     = ["ubuntu", "thein3rovert"]
}

variable "gcp_ssh_extra_keys" {
  type        = list(string)
  description = "Extra raw SSH key lines (user:key) appended as-is, e.g. keys added via console"
  default     = []
}

variable "gcp_tags" {
  type        = list(string)
  description = "Network tags"
  default     = ["terraform-managed", "prod"]
}

variable "gcp_labels" {
  type        = map(string)
  description = "Resource labels"
  default = {
    environment = "production"
    managed_by  = "terraform"
  }
}

variable "gcp_startup_script" {
  type        = string
  description = "Startup script"
  default     = null
}

#========= GCP Secrets =================

variable "tailscale_authkey" {
  type        = string
  description = "Tailscale authentication key"
  sensitive   = true
}

#========= GCP Storage =================

variable "gcp_infra_bucket_name" {
  type        = string
  description = "GCS bucket name for infrastructure storage (Terraform state, configs, backups)"
}
