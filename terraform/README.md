# Terraform layout

## Convention: shallow provider-first

Group by **vendor first, capability second** — max 2 levels under `modules/`.
Vendors match how this homelab is actually operated (Proxmox vs GCP vs
Cloudflare each have their own auth and quirks). Cross-vendor platforms
(`k3s`, `rancher`) stay top-level.

Target layout (HML-052 tracks the migration):

```
terraform/
  envs/
    dev/                  # dev environment, thin: inputs + module calls
    prod/                 # prod environment, thin: inputs + module calls
  modules/
    proxmox/
      vm/
      lxc/
    incus/
      vm/
    gcp/
      vm/
      bucket/
      secret-manager/
      service-account/
    cloudflare/
      dns/
    uptimekuma/
      monitors/
    k3s/                  # platform, runs on Proxmox VMs
    rancher/              # platform
    cloud-init/           # base helper
```

## Rules for agents

1. New module goes at `terraform/modules/<vendor-or-platform>/<capability>/`
   with `version.tf`, `variables.tf`, `main.tf`, `outputs.tf`, `README.md`.
2. Modules take variables only — no env-specific values, no Vault reads
   inside modules. Secrets come from Vault data sources in `envs/*/*.tf`
   (see `envs/prod/cloudflare.tf` pattern: `secret/<name>` + locals).
3. Envs stay thin: provider blocks, Vault lookups, module calls with maps.
4. DNS-style changes use `-target=module.<name>` for plan/apply so prod
   infra is never touched by accident.
5. Never commit secrets. API tokens live in Vault, referenced by key.
6. Moving a module changes its state address — ship `moved` blocks and
   prove with a zero-change plan (see HML-052).
7. Every module gets a README: what it manages, how to add one more of
   the thing, how to import existing resources.

## Validate

```bash
terraform -chdir=terraform/modules/<vendor>/<capability> fmt
terraform -chdir=terraform/modules/<vendor>/<capability> init -backend=false
terraform -chdir=terraform/modules/<vendor>/<capability> validate
```
