# Cloudflare DNS module

Manages `thein3rovert.dev` records. Called from `terraform/envs/prod/cloudflare.tf`.
Token comes from Vault `secret/cloudflare:dns-token` (see `cloudflare.tf`).

## Add a new DNS record

1. Add an entry to the `records` map in `terraform/envs/prod/cloudflare.tf`:

```hcl
newapp = {
  name    = "newapp.thein3rovert.dev"
  type    = "A"
  content = var.origin_ip
  proxied = false
  ttl     = 1
  comment = "newapp"
}
```

2. If the record **already exists** in Cloudflare (created in dashboard), import it first or `apply` will try to duplicate it:

```bash
cd terraform/envs/prod
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.gcp/terraform-key.json"
export CLOUDFLARE_API_TOKEN='vault kv get -field=dns-token secret/cloudflare'
ID=$(curl -s "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=newapp.thein3rovert.dev" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" | jq -r '.result[0].id')
terraform import 'module.dns.cloudflare_dns_record.this["newapp"]' "$ZONE_ID/$ID"
```

Or add the `TYPE NAME` pair to `cloudflare-import.sh` `WANT` map and re-run it.

3. Apply DNS only (never full apply for a DNS change):

```bash
terraform plan -target=module.dns
terraform apply -target=module.dns
```

## Rules

| Case | `proxied` | `ttl` |
| ---- | --------- | ----- |
| Normal web app | `true` | `1` (Auto) |
| S3 / MinIO / Forgejo (`code`), large uploads | `false` | `1` |
| `ssh` (proxy breaks SSH) | `false` | `1` |
| Custom TTL, e.g. 10 min | `false` | `600` |

`ttl = 1` means Auto in Cloudflare. `proxied = true` requires `ttl = 1`.

## Delete a record

Remove its block from `cloudflare.tf`, then `plan` / `apply -target=module.dns`.
Terraform deletes it from Cloudflare.
