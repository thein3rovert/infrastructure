# just is a command runner, Justfile is very similar to Makefile, but simpler.
############################################################################
#
#  Common recipes
#
############################################################################

# List all recipes.
_default:
    @printf '\033[1;36mnixcfg recipes\033[0m\n\n'
    @printf '\033[1;33mUsage:\033[0m just <recipe> [args...]\n\n'
    @just --list --list-heading $'Available recipes:\n\n'


[group('jnix')]
info:
  jnix info

[group('jnix')]
dry-run:
  jnix fs-dryrun

[group('jnix')]
clean:
  jnix fs

# TODO: MVOE ALL TO NEW MODULES FORMAT

# Update glance service
[group('servers')]
update-glance:
    ansible-playbook -i ansible/inventory.ini ansible/playbooks/restart-glance.yml

# Update agenix secrets
[group('flake')]
update-nix input:
  nix flake update {{input}}

# ==============================
#       ANSIBLE COMMANDS
# ==============================

# List available ansible roles
[group('ansible')]
list-roles:
    @ls -1 ansible/roles/ | grep -v README.md

# List hosts in inventory
[group('ansible')]
list-hosts env="production":
    ansible-inventory -i ansible/inventory/{{ env }}.yml --list

# Run all playbooks on production
[group('ansible')]
ansible-all:
    cd ansible && just all

# Run all playbooks on dev
[group('ansible')]
ansible-all-dev:
    cd ansible && just all-dev

# Run a specific role on production
[group('ansible')]
run role:
    cd ansible && just run {{ role }}

# Run a specific role on dev
[group('ansible')]
run-dev role:
    cd ansible && just run-dev {{ role }}

# Run a specific role on a specific host
[group('ansible')]
run-host role host env="production":
    cd ansible && just run-host {{ role }} {{ host }} {{ env }}

# Dry run a specific role on a specific host
[group('ansible')]
dry-run-host role host env="production":
    cd ansible && just dry-run-host {{ role }} {{ host }} {{ env }}

# Ping a specific host
[group('ansible')]
ansible-ping host env="production":
    cd ansible && just run-host ping {{ host }} {{ env }}

# Edit ansible vault
[group('ansible')]
vault-edit:
    cd ansible && just edit

# Run a specific environment (production, dev)
[group('ansible')]
ini env:
  ansible-inventory --list -i ansible/inventory/{{ env }}.yml

# ==============================
#       KESTRA
# ==============================

# Restart Kestra service on marcus
[group('kestra')]
kestra-restart:
    cd ansible && just kestra-restart

[group('terraform')]
init env:
  #!/usr/bin/env bash
  source ~/.proxmox_api_secrets
  export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.gcp/terraform-key.json"
  cd ./terraform/envs/{{ env }} && terraform init

[group('terraform')]
plan env:
  #!/usr/bin/env bash
  source ~/.proxmox_api_secrets
  export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.gcp/terraform-key.json"
  cd ./terraform/envs/{{ env }} && terraform plan

[group('terraform')]
apply env:
  #!/usr/bin/env bash
  source ~/.proxmox_api_secrets
  export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.gcp/terraform-key.json"
  cd ./terraform/envs/{{ env }} && terraform apply


[group('terraform')]
validate env:
  #!/usr/bin/env bash
  source ~/.proxmox_api_secrets
  export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.gcp/terraform-key.json"
  cd ./terraform/envs/{{ env }} && terraform validate

[group('terraform')]
destroy env:
  #!/usr/bin/env bash
  source ~/.proxmox_api_secrets
  export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.gcp/terraform-key.json"
  cd ./terraform/envs/{{ env }} && terraform destroy

# [group('ansible')]
# ini-dev:
#   ansible-inventory --list -i ansible/inventory/dev.yml
