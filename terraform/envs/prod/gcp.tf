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
