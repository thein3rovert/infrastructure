#!/usr/bin/env bash
# Import existing Cloudflare records into terraform/envs/prod state.
# Run from terraform/envs/prod.
# Usage: CLOUDFLARE_API_TOKEN=xxxx ./cloudflare-import.sh
set -euo pipefail

ZONE_ID="${ZONE_ID:-f1dafae189acc6d796c0603bcedcbc00}"

if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
  echo "Set CLOUDFLARE_API_TOKEN first (same value as Vault secret/cloudflare dns-token)"
  exit 1
fi

declare -A WANT=(
  [apex]="A thein3rovert.dev"
  [blog]="A blog.thein3rovert.dev"
  [code]="A code.thein3rovert.dev"
  [freshrss]="A freshrss.thein3rovert.dev"
  [gallery]="A gallery.thein3rovert.dev"
  [glance]="A glance.thein3rovert.dev"
  [linkding]="A linkding.thein3rovert.dev"
  [memos]="A memos.thein3rovert.dev"
  [minio]="A minio.thein3rovert.dev"
  [minio-console]="A minio-console.thein3rovert.dev"
  [s3]="A s3.thein3rovert.dev"
  [s3-console]="A s3-console.thein3rovert.dev"
  [ssh]="A ssh.thein3rovert.dev"
  [uptime-kuma]="A uptime-kuma.thein3rovert.dev"
  [www]="CNAME www.thein3rovert.dev"
  [dmarc]="TXT _dmarc.thein3rovert.dev"
)

TMP=$(mktemp)
curl -s "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?per_page=100" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  -H "Content-Type: application/json" > "$TMP"

if ! jq -e '.success' "$TMP" > /dev/null; then
  echo "Cloudflare API error:"
  jq '.errors' "$TMP"
  exit 1
fi

for key in "${!WANT[@]}"; do
  read -r want_type want_name <<< "${WANT[$key]}"
  id=$(jq -r --arg t "$want_type" --arg n "$want_name" \
    '.result[] | select(.type==$t and .name==$n) | .id' "$TMP" | head -n 1)
  if [[ -z "$id" ]]; then
    echo "SKIP $key ($want_type $want_name): not found in Cloudflare"
    continue
  fi
  echo "IMPORT $key -> $id"
  terraform import "module.dns.cloudflare_dns_record.this[\"$key\"]" "${ZONE_ID}/${id}" || true
done

rm -f "$TMP"
echo "Done. Run: terraform plan -target=module.dns"
