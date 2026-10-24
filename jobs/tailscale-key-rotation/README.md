# Tailscale Key Rotation

Scheduled monitoring + rotation of the shared reusable Tailscale auth key
(consumed by NixOS hosts via agenix), stored in GCP Secret Manager.

## How it runs (current)

Kestra flow `ops.tailscale-key-rotation` (weekly) → Ansible ops playbook
`playbooks/key-rotation.yml` (dry-run default) → `src/rotate.py`.

Identity lives in `terraform/modules/infra/providers/gcp/service-account/`,
used from `terraform/envs/prod/main.tf`. Cloud Run + Scheduler were dropped
in favour of the Kestra path.

## Local use

```bash
cp .env.example .env   # fill in, never commit
set -a; source .env; set +a
python3 src/rotate.py            # dry-run first: DRY_RUN=true
```

Via Ansible (repo root `playbooks`):

```bash
ansible-playbook -i inventory/production.yml playbooks/key-rotation.yml \
  --tags key-rotation \
  -e rotation_script_path=/path/to/infrastructure/jobs/tailscale-key-rotation/src/rotate.py
```

Live run (creates keys + versions): add `-e rotation_dry_run=false`.

## Tests

```bash
python3 -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt
python3 -m pytest tests/ -q
```

Covers: outside/inside/expired window, missing + malformed expiry, API
failures + rate limits, Secret Manager read/write failures, create-ok +
store-fail recovery, lock contention, dry-run, notify failure, rerun
idempotency, secret-free logs.

## Runbook

| Situation | Action |
| :--- | :--- |
| Check flagged expiry | Run dry-run; confirm days-left in logs |
| Rotate for real | Re-run with `rotation_dry_run=false`; verify `rotated` + version in GCP console |
| Store failed after create | New key exists but unrecorded: find it in Tailscale admin (by creation time), then either adopt via labels or revoke it; rerun |
| Concurrent runs | Second runner exits on lock; no duplicates by design |
| API token dead/expired | Mint a new token in Tailscale admin console (manual), update `vars/vault.yml` (`tailscale_api_token`) |
| Roll back a rotation | Previous key retained by default: point consumers back, then revoke the new key in admin console |
| Revoke old key | Only with explicit approval: `-e rotation_revoke_previous=true` |

## Security notes

- No secrets in repo, logs, or Terraform state beyond the pre-existing
  `tailscale-authkey` version managed by `terraform/envs/prod` (migrate
  versions out of Terraform before rotation goes live).
- Rotation state lives in secret labels (`rotation-current-key-id`,
  `rotation-current-expiry`); never trust version timestamps for expiry.
- Enrolled devices are unaffected by rotation; only new provisioning
  uses the fresh key.
- NixOS hosts read the new key on next rebuild via the agenix
  `tailscale-auth.age` files — syncing Secret Manager into the
  `secret-vault` repo is currently a documented manual step
  (`agenix -e tailscale/shared/tailscale-auth.age`).
