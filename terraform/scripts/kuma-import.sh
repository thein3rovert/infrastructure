#!/usr/bin/env bash
# Import existing Uptime Kuma monitors into terraform/envs/prod state.
# Run from terraform/envs/prod. Requires VAULT_TOKEN + GCS creds.
# IDs captured 2026-10-28 from kuma.db on bellamy.
set -euo pipefail

imp() {
  echo "IMPORT $1 -> $2"
  terraform import "$1" "$2" || true
}

imp 'module.uptimekuma.uptimekuma_monitor_http.this["blog"]' "1"
imp 'module.uptimekuma.uptimekuma_monitor_postgres.this["postgresql"]' "4"
imp 'module.uptimekuma.uptimekuma_monitor_dns.this["dns"]' "5"
imp 'module.uptimekuma.uptimekuma_monitor_http.this["garage"]' "6"
imp 'module.uptimekuma.uptimekuma_monitor_ping.this["emily"]' "8"
imp 'module.uptimekuma.uptimekuma_monitor_ping.this["finn"]' "9"
imp 'module.uptimekuma.uptimekuma_monitor_ping.this["marcus"]' "10"
imp 'module.uptimekuma.uptimekuma_monitor_ping.this["lincoln"]' "11"
imp 'module.uptimekuma.uptimekuma_monitor_ping.this["octavia"]' "12"
imp 'module.uptimekuma.uptimekuma_monitor_ping.this["github-runner"]' "13"
imp 'module.uptimekuma.uptimekuma_monitor_ping.this["raven"]' "14"

echo 'Done. Run: terraform plan -target=module.uptimekuma'
