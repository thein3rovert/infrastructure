---
id: HML-049
title: Manage Cloudflare DNS with Terraform
status: Done
assignee: []
created_date: '2026-10-25 17:25'
updated_date: '2026-10-25 17:48'
labels: []
dependencies: []
priority: medium
ordinal: 64000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Import 16 existing thein3rovert.dev records into Terraform using Vault secret/cloudflare dns-token, isolated cloudflare env with GCS backend.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 New terraform/envs/cloudflare stack validates
- [x] #2 Module covers all 16 records with correct proxied/TTL
- [x] #3 Import script provided for existing records
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Create cloudflare dns module with for_each records 2. Create isolated terraform/envs/cloudflare stack with Vault token + GCS backend 3. Encode 16 current records with proxied/TTL 4. Provide import script via API record IDs 5. terraform validate + fmt
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
terraform validate Success, fmt clean, init -backend=false ok. 16 records encoded with current proxied/TTL. import.sh uses API to map name->ID and terraform import. Plan/apply left to user (needs VAULT_TOKEN + GCS creds).

Per user convention (envs = dev/prod only): removed terraform/envs/cloudflare stack, folded into terraform/envs/prod/cloudflare.tf + vars + cloudflare-import.sh. Module validates (Success), fmt clean. Prod validate blocked here by missing GCS/Vault creds - run plan where creds exist. flake.lock secrets rev bump is user deploy, keep.

User imported all 16 records and applied: 0 added, 16 changed (comment-only), 0 destroyed. DNS now Terraform-managed via prod/cloudflare.tf.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
New isolated terraform/envs/cloudflare stack + cloudflare/dns module managing 16 records. Vault secret/cloudflare dns-token wired. import.sh provided. Validated.
<!-- SECTION:FINAL_SUMMARY:END -->
