---
id: HML-051
title: ArgoCD and Longhorn unreachable - lincoln cross-node pod traffic broken
status: Done
assignee: []
created_date: '2026-10-25 19:42'
updated_date: '2026-10-25 20:05'
labels: []
dependencies: []
priority: high
ordinal: 66000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
All argocd backend pods and longhorn-ui sit on lincoln; pod traffic between lincoln and other nodes hangs while node, etcd and Tailscale are healthy. Likely k3s embedded flannel on lincoln lost VXLAN peers. Mitigate by rescheduling off lincoln, fix by restarting k3s on lincoln via Proxmox.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 ArgoCD UI/API reachable via argocd.l.thein3rovert.com
- [x] #2 Longhorn UI consistently reachable without timeouts
- [x] #3 Cross-node pod traffic to/from lincoln verified working
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Cordon lincoln 2. Delete argocd-server + longhorn-ui pods to reschedule onto raven/octavia 3. Verify endpoints + HTTP 200 via ingress path 4. Leave uncordon + k3s restart on lincoln for user via Proxmox
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
Mitigation complete: cordoned lincoln+octavia, rescheduled argocd-server + longhorn-ui onto raven, repointed traefikk backends (linkding/longhorn/argocd) to raven tailscaleIp + added raven host entry, rebuilt nixos host. Verified: argocd 200, longhorn 200, linkding 302 via l.thein3rovert.com. AC3 NOT done: cross-node pod traffic still blackholed (flannel annotations correct, suspect UDP 8472/MTU). Needs k3s restart on lincoln via Proxmox + uncordon + move registry back.

User restarted node(s) via Proxmox but overlay still dead: raven->lincoln, lincoln->raven, octavia->raven all hang. New evidence: lincoln pods cannot reach API ClusterIP 10.43.0.1 (argocd-redis secret-init i/o timeout) and csi sidecars cannot reach local csi.sock. Points to node-level forwarding/firewall on lincoln (FORWARD chain, ip_forward, UDP 8472) not flannel config. Re-cordoned lincoln+octavia to protect workloads. PodCIDRs clean, no overlap.

ROOT CAUSE: tailscaled restarted on raven 12:32 (ActiveEnterTimestamp), flannel.1 deleted and flannel retry loop could not re-resolve tailscale0 (external interface not found) - stale netlink state. Same on octavia. Lincoln was healthy all along. FIX: systemctl restart k3s on raven + octavia, flannel.1 + routes rebuilt. Verified: cross-node matrix OK all pairs, DNS from lincoln pod resolves, argocd/longhorn/linkding 200/200/302 via traefikk. Uncordoned. Traefik backends stay on raven (working); moving back to octavia optional.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
ArgoCD/Longhorn outage was dead flannel overlay on raven+octavia after tailscaled restart; fixed with k3s restarts. All services verified 200.
<!-- SECTION:FINAL_SUMMARY:END -->
