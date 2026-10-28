# Uptime Kuma monitors module

Provider: `breml/uptimekuma` (~> 0.4). No official provider exists; this is
the most complete community one. Auth is admin username + password (Kuma has
no scoped tokens), so credentials live in Vault, never in git.

> **Known limitation (provider 0.4.0):** connect hard-requires the server's
> `maintenanceList` event, but Kuma's send runs in `Promise.allSettled` — a
> single maintenance row that fails to serialize kills the emit silently and
> EVERY terraform run times out with `(missing events: maintenanceList)`.
> Keep maintenances at zero, or only rows created by the provider itself
> (v2-native format). If plans suddenly start timing out on connect, check
> Kuma → Maintenance for a broken row before anything else.

## Add a monitor

Add an entry to the matching map in the env call (e.g.
`terraform/envs/prod/uptimekuma.tf`):

```hcl
http_monitors = {
  blog = {
    url    = "https://blog.thein3rovert.dev"
    interval = 60
    # expiry_notification defaults true: warns before TLS cert expires
  }
}
```

Then targeted plan/apply (never full apply for a monitoring change):

```bash
cd terraform/envs/prod
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.gcp/terraform-key.json"
terraform plan -target=module.uptimekuma
terraform apply -target=module.uptimekuma
```

## Import an existing monitor

If the monitor already exists in the Kuma UI, import it first or apply
will create a duplicate. List monitors via the UI (Settings shows IDs in
the URL when editing, e.g. `/dashboard/12`), then:

```bash
terraform import 'module.uptimekuma.uptimekuma_monitor_http.this["blog"]' 12
```

## Rules

- HTTPS endpoints: `expiry_notification = true` (default) catches cert
  renewal failures like the Traefik migration.
- `interval` minimum is 20s (provider-enforced).
- Auth-gated pages (dashboard behind basic auth): prefer a TCP/ping
  monitor on the host, or use `uptimekuma_monitor_http_keyword` later —
  plain HTTP checks 401 otherwise.
