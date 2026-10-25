---
id: HML-047
title: Boot Roan without retired Nightblood NFS dependency
status: Done
assignee:
  - '@AI-Assistant'
created_date: '2026-10-25 10:51'
updated_date: '2026-10-25 10:57'
labels:
  - proxmox
  - roan
  - backup
dependencies: []
references:
  - hosts/roan/configuration.nix
priority: high
type: bug
ordinal: 62000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
User approved removing the Nightblood bind mount and disabling its dependent backup service so Roan (LXC 103 on mount-weather 192.168.0.20) can boot. Confirmed mp0=/mnt/nightblood,mp=/mnt/nightblood; host stat returns Stale file handle, causing LXC pre-start exit 116. Preserve all container and Nightblood data; do not remount or repair the failing Nightblood disk as part of this fix.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Roan starts successfully without a Nightblood NFS bind mount
- [x] #2 The NFS-dependent backup service is disabled before normal boot and remains disabled in declarative Nix configuration
- [x] #3 Other configured Roan services are verified after startup and any residual failure is reported
- [x] #4 No Nightblood data or container disks are deleted or reformatted
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
1. Preserve the existing CT configuration and detach only mp0 with the Proxmox CLI. 2. Mount the stopped root filesystem and inspect startup units; prevent the NFS-dependent backup service from starting before normal boot. 3. Persist the retirement in Roan Nix configuration. 4. Start CT103 and verify service state, absence of NFS dependency, and data-preserving changes. 5. Record evidence, commit only scoped changes, and push.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
2026-10-25 recovery completed: saved original Proxmox CT configuration on mount-weather at /root/roan-103-before-nfs-retirement-20261025T105212.conf, removed only bind-mount mp0 using pct set 103 --delete mp0, and mounted the stopped rootfs for a boot-safe mask. The guest NixOS /etc/systemd/system is declaratively managed, so placed a persistent /etc/systemd/system.control/podman-zerobyte.service -> /dev/null mask in the higher-priority systemd load path, with guest-root ownership (host UID/GID 100000). Offline systemctl reported masked before any normal startup; podman-restart.service was linked, not enabled. Unmounted rootfs, started CT103, and waited for NixOS startup. Verified status=running, systemd is-system-running=running, zero failed units, Zerobyte LoadState/UnitFileState=masked and ActiveState=inactive, no Zerobyte container running, and no NFS/NFS4 mounts inside Roan. Rootfs remains local-lvm:vm-103-disk-0,size=20G, with no mp entries. Existing /var/lib/containers/zerobyte directory remains present; no Nightblood or container disks were erased/formatted. Other application containers kaneo, guacd, dbpro-studio, fossflow, dockhand and termix are running; Grafana, Prometheus, Loki, Vector, Tailscale and sshd.socket are active. SSH socket activation explains inactive sshd.service; direct SSH works. Local HTTP health checks returned 200 for Grafana :3010/api/health, Prometheus :3020/-/ready and Loki :3030/ready. Direct LAN monitoring requests timed out (firewall), so do not claim LAN exposure; services are intended to be reachable over Tailscale. Nix source now disables zerobyte and removes Nightblood volumes; nix eval confirms zerobyte.enable=false and no zerobyte OCI container. Nix parse and git diff --check passed. Proxmox host NFS mount and Nightblood server were intentionally left untouched; Roan no longer depends on them. Persistent guest mask takes effect immediately and across reboots, without requiring a broad NixOS upgrade.

Final external check: all three monitoring endpoints also returned HTTP 200 over the expected Tailscale address 100.99.235.113 (:3010/api/health, :3020/-/ready, :3030/ready). The brief Proxmox SSH banner timeout resolved on retry; direct guest SSH and subsequent pct status both succeeded.
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Restored Roan (CT103) by removing its stale Nightblood NFS bind mount and persistently masking Zerobyte before boot; declarative Nix configuration now disables Zerobyte. Verified running guest, zero failed units, backup service masked/inactive, no guest NFS mounts, preserved backup data directory, active app/monitoring services, and HTTP 200 monitoring health checks locally and over Tailscale. No disks were reformatted and no backup data was deleted.
<!-- SECTION:FINAL_SUMMARY:END -->
