---
id: HML-048
title: Switch Traefik ACME DNS-01 from GoDaddy to Cloudflare
status: Done
assignee: []
created_date: '2026-10-25 16:36'
updated_date: '2026-10-25 16:38'
labels: []
dependencies: []
priority: high
ordinal: 63000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
GoDaddy DNS migrated to Cloudflare. Traefik still uses godaddy DNS challenge provider which will fail for renewals. Switch all certResolvers to cloudflare provider with CF_DNS_API_TOKEN.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Traefik certificatesResolvers uses cloudflare provider
- [x] #2 All certResolver references updated from godaddy to cloudflare
- [x] #3 systemd EnvironmentFile points to cloudflare age secret
- [x] #4 nix check / build passes for bellamy
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Add cloudflare age secret entry in hosts/bellamy/secrets.nix 2. Update traefik default.nix certificatesResolvers godaddy->cloudflare provider + delay 30s + EnvironmentFile 3. Update all certResolver godaddy->cloudflare in 8 service files + base containers default 4. Verify with nix flake check / nixos-rebuild dry-build for bellamy
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Verified: nix eval provider=cloudflare, certificatesResolvers=[cloudflare], EnvironmentFile=.traefik-cloudflare, grep clean in modules/, nixos-rebuild dry-build bellamy succeeded. Old godaddy age entry kept for rollback.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Switched Traefik ACME DNS-01 godaddy->cloudflare across 9 files + new cloudflare age secret. Verified with nix eval and dry-build bellamy.
<!-- SECTION:FINAL_SUMMARY:END -->
