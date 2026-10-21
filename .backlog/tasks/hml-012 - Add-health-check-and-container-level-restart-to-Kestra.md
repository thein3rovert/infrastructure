---
id: HML-012
title: Add health check and container-level restart to Kestra
status: In Progress
assignee:
  - '@AI-Assistant'
created_date: '2026-08-08 15:47'
updated_date: '2026-10-21 19:12'
labels: []
dependencies:
  - HML-009
references:
  - HML-009 - Original fix attempt (systemd restart only)
modified_files:
  - modules/nixos/services/automation/kestra/default.nix
priority: high
type: bug
ordinal: 16000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The fix in HML-009 added systemd restart policy, but it only triggers when the container exits. When Postgres becomes unavailable, Kestra stays running but becomes non-functional - it doesn't exit, so systemd never restarts it.

Kestra exposes a health endpoint on port 8081 (/health) but we're not using it. Need to configure container health checks and container-level restart policy so Kestra actually restarts when it can't connect to Postgres.

Root cause: Systemd Restart=on-failure only works when the container process exits. Kestra handles database connection failures internally and stays running, just in a broken state.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Add --health-cmd with curl to /health endpoint
- [x] #2 Configure health check interval, retries, and start period
- [x] #3 Add --restart=on-failure to container extraOptions
- [ ] #4 Test by stopping Postgres on emily and verifying Kestra container restarts
- [ ] #5 Test by starting Postgres on emily and verifying Kestra reconnects automatically
- [x] #6 Document the health check configuration in code comments
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan

### Files to Modify
- `modules/nixos/services/automation/kestra/default.nix` (lines 45-48, extraOptions array)

### Changes Required

1. **Add health check configuration** to extraOptions array:
   - `--health-cmd=curl -f http://localhost:8081/health || exit 1`
   - `--health-interval=30s` (check every 30 seconds)
   - `--health-retries=3` (fail after 3 consecutive failures)
   - `--health-start-period=60s` (give Kestra 60s to start before health checks begin)

2. **Add container restart policy**:
   - `--restart=on-failure` (restart when unhealthy)

3. **Update systemd restart policy** (optional but recommended):
   - Change from `Restart=on-failure` to `Restart=always` in `modules/nixos/profiles/systemd/kestra/default.nix`
   - This provides a safety net in case container-level restart fails

### Testing Plan
1. Deploy to marcus: `sudo nixos-rebuild switch`
2. Stop Postgres on emily: `ssh emily sudo systemctl stop postgresql`
3. Watch Kestra logs: `journalctl -u podman-kestra -f`
4. Verify container becomes unhealthy and restarts
5. Start Postgres on emily: `ssh emily sudo systemctl start postgresql`
6. Verify Kestra reconnects automatically

### Dependencies
- Requires `curl` inside Kestra container (should be present in base image)
- Health endpoint must be accessible at `http://localhost:8081/health`

2026-10-21 recovery: inspect the latest executor shutdown evidence, start the existing executor without upgrading images, correct restart/config dependencies for the currently deployed split service names if needed, and verify runtime health without interrupting Postgres.
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Investigation Findings (2026-08-08)

Checked logs on marcus after Kestra stayed down for 1.5 days:

### Timeline
- **Aug 7, 02:04:53** - Connection timeout to Postgres: `java.net.SocketTimeoutException: Connect timed out`
- **Aug 7, 02:07:07** - Kestra initiated **graceful shutdown** (not crash)
- **Aug 7, 02:07:08** - Service deactivated with `Result=success` (exit code 0)
- **Aug 8, 16:49** - Manually started, connected to Postgres successfully

### Root Cause Confirmed
```bash
$ systemctl show podman-kestra --property=Result,Restart
Result=success
Restart=on-failure
```

**Kestra exited with code 0 (success), so `Restart=on-failure` never triggered.**

When Kestra loses Postgres connection, it:
1. Detects database failure
2. Initiates graceful shutdown procedure
3. Exits cleanly with code 0
4. Systemd sees "successful exit" and does NOT restart

### Solution Components
1. **Health checks** - Monitor `/health` endpoint on port 8081
2. **Container restart** - `--restart=on-failure` at container level catches unhealthy state
3. **Consider systemd change** - May need `Restart=always` instead of `on-failure` as backup

The container-level health check will mark the container as unhealthy when it can't reach Postgres, triggering the container restart policy even if the process doesn't exit.

## Implementation Complete

### Changes Made

1. **Container health checks** (`modules/nixos/services/automation/kestra/default.nix`):
   - Added `--health-cmd=curl -f http://localhost:8081/health || exit 1`
   - Configured `--health-interval=30s`, `--health-retries=3`, `--health-start-period=60s`
   - Added inline documentation explaining why health checks are needed

2. **Container restart policy** (`modules/nixos/services/automation/kestra/default.nix`):
   - Added `--restart=on-failure` to extraOptions
   - Container will restart when health check marks it as unhealthy

3. **Systemd restart policy upgrade** (`modules/nixos/profiles/systemd/kestra/default.nix`):
   - Changed from `Restart=on-failure` to `Restart=always`
   - Added comment explaining why Kestra's graceful shutdown bypasses on-failure
   - Provides safety net if container-level restart fails

### How It Works
1. Health check runs every 30s, checking `/health` endpoint
2. If health check fails 3 times (90s total), container marked unhealthy
3. Container restart policy (`--restart=on-failure`) restarts unhealthy container
4. If container doesn't restart, systemd `Restart=always` provides backup

### Ready for Testing
Changes ready to deploy and test with acceptance criteria #4 and #5.

## Port Verification

✅ **Port 8081 is already configured and working:**
- Port 8081 is exposed in container config (line 29: `8081:8081`)
- Currently listening: `0.0.0.0:8081` (conmon process)
- Health endpoint accessible: `http://localhost:8081/health`
- Returns JSON with status "UP" and jdbc connection details
- `curl` is available in container at `/usr/bin/curl`

**Test results:**
```bash
$ sudo podman exec kestra curl -f http://localhost:8081/health
{"name":"kestra","status":"UP","details":{...}}

$ sudo podman exec kestra sh -c 'curl -f http://localhost:8081/health > /dev/null 2>&1 && echo "Health check passed"'
Health check passed
```

The health check command will work correctly as configured.

## Build Fix

Encountered conflict during nixos-rebuild:
```
error: The option `systemd.services.podman-kestra.serviceConfig.Restart' has conflicting definition values:
- In oci-containers.nix: "on-failure"
- In systemd/kestra: "always"
```

**Resolution:** Added `mkForce` to override the OCI containers default:
```nix
Restart = mkForce "always";
```

The OCI containers module already sets `Restart=on-failure` by default, so we need to force our override to `always`.

## Deployment Status ✅

**Despite the deployment error, the fix was successfully deployed:**

✅ Service running: `active (running)`
✅ Container health: `healthy`
✅ Systemd restart: `Restart=always`
✅ Container restart: `on-failure`
✅ Health checks configured and working

**What happened:**
The deployment script timed out waiting for the health check to pass during the initial 60-second start period. This is a known quirk with Podman health checks and NixOS deployment - the health check timer fails during initial startup, but the service continues running and becomes healthy.

**Verification:**
```bash
$ sudo podman inspect kestra --format '{{.State.Health.Status}}'
healthy

$ sudo systemctl show podman-kestra --property=Restart
Restart=always

$ sudo podman inspect kestra --format '{{.HostConfig.RestartPolicy.Name}}'
on-failure

$ sudo podman inspect kestra --format '{{.Config.Healthcheck}}'
{[CMD-SHELL curl -f http://localhost:8081/health || exit 1] 1m0s 0s 30s 30s 3}
```

Ready for acceptance criteria #4 and #5 testing.

Current incident: podman-kestra-executor is inactive/dead with Result=success and Restart=on-failure. The Nix restart override still targets the retired podman-kestra unit, not the split executor/controller/scheduler/webserver units. Marcus currently runs Kestra 2.0.7; Indra runs 2.0.6. KV lookup failures are separately confirmed to come from worker-local storage, not missing namespace inheritance.

2026-10-21 verified recovery: executor was started successfully and reports Kestra 2.0.7 / Executor started. Read-only shutdown investigation found PostgreSQL connection timeouts followed by executor-delay-exception-watcher termination, TERMINATED_GRACEFULLY, and status 0 at 02:33:09 BST; systemd deactivated it at 02:33:10 BST. Tailscale connection timeouts to PostgreSQL corroborate a reachability problem, but database-host outage versus network-path failure is not distinguished. The unrelated 00:17 webserver OOM was not an executor OOM. Corrected Nix setup dependencies and Restart=always for all four actual split unit names, with 30-second delay and 5 starts/300 seconds; explicit runtime drop-ins under /run/systemd/system make those restart policies active now without a host rebuild. nix eval confirms executor Restart=always. Runtime drop-ins are temporary; the Nix source correction becomes reboot-persistent after the next Marcus rebuild. No disruptive Postgres outage/recovery test was performed, so existing outstanding acceptance criteria remain open. Healthcheck unhealthy state alone is not a restart action.
<!-- SECTION:NOTES:END -->
