# Postgres Backup GCS Sync - Kestra Setup

This guide explains how to set up and deploy the Postgres backup sync workflow to Kestra.

## Prerequisites

1. Kestra instance running (✅ you have this at `nixos (Emily)`)
2. Playbooks repo: https://github.com/thein3rovert/playbooks
3. GCP service account JSON key
4. SSH access to bellamy (postgres host)

## Step 1: Configure Kestra KV Store

Add these keys to Kestra KV store (Settings → KV Store):

### Required Keys

```bash
# SSH access
SSH_PRIVATE_KEY           # Deprecated: SSH key now comes from Vault secret/ssh at runtime
ANSIBLE_VAULT_PASSWORD    # Your Ansible vault password

# Host configuration
BELLAMY_HOST              # IP or hostname of postgres server (e.g., 100.105.187.63)
BELLAMY_USER              # SSH user for bellamy (e.g., thein3rovert)

# GCP credentials
GCP_SERVICE_ACCOUNT_JSON  # Full JSON content of GCP service account key
```

### How to Add GCP Service Account JSON

**Option 1: Via Kestra UI**

1. Go to Kestra → Settings → KV Store
2. Click "Add Key"
3. Key: `GCP_SERVICE_ACCOUNT_JSON`
4. Value: Paste the entire JSON content (not the file path!)
   ```json
   {
     "type": "service_account",
     "project_id": "thein3rovertproject",
     "private_key_id": "...",
     "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
     "client_email": "terraform@thein3rovertproject.iam.gserviceaccount.com",
     ...
   }
   ```
5. Save

**Option 2: Via Kestra API**

```bash
# Read your GCP service account JSON
GCP_JSON=$(cat ~/.gcp/terraform-key.json)

# Add to Kestra KV store
curl -X PUT "http://trikru:8080/api/v1/namespaces/ops/kv/GCP_SERVICE_ACCOUNT_JSON" \
  -H "Content-Type: application/json" \
  -d "{\"value\": $(jq -Rs . ~/.gcp/terraform-key.json)}"
```

## Step 2: Deploy Workflow to Kestra

**Option 1: Via Kestra UI**

1. Go to Kestra → Flows
2. Click "Create"
3. Copy content from `kestra/production/postgres-backup-gcs-sync.yml`
4. Paste and save

**Option 2: Via Kestra CLI (if installed)**

```bash
kestra flow namespace update ops \
  kestra/production/postgres-backup-gcs-sync.yml
```

**Option 3: Via API**

```bash
curl -X POST "http://trikru:8080/api/v1/flows" \
  -H "Content-Type: application/x-yaml" \
  --data-binary @kestra/production/postgres-backup-gcs-sync.yml
```

## Step 3: Test the Workflow

### Manual Test Run

1. Go to Kestra → Flows → `ops.postgres-backup-gcs-sync`
2. Click "Execute"
3. Monitor the execution in real-time
4. Check logs for each task

### Expected Output

```
✅ GCP credentials deployed to bellamy
✅ Ansible playbook executed
✅ Backups uploaded to GCS
✅ All database backups verified
📊 Total backup size: 50.2 MiB
🧹 Cleaned up GCP credentials from bellamy
```

## Step 4: Verify in GCS

```bash
# List backups (from your local machine)
export GOOGLE_APPLICATION_CREDENTIALS=~/.gcp/terraform-key.json
gsutil ls -lh gs://iv3-infra-us-prod/postgres-backups/

# Should see:
# gs://iv3-infra-us-prod/postgres-backups/n8n.sql.gz
# gs://iv3-infra-us-prod/postgres-backups/forgejo.sql.gz
# gs://iv3-infra-us-prod/postgres-backups/kestra.sql.gz
# gs://iv3-infra-us-prod/postgres-backups/kaneo.sql.gz
```

## Scheduled Execution

The workflow is configured to run:

- **Schedule**: Daily at 03:15 AM (Europe/London timezone)
- **Trigger**: `daily-after-backup`
- **Why 03:15**: Postgres backups run at 03:10 AM, giving 5 minutes buffer

To enable the schedule:

1. Workflow is already configured with trigger
2. Kestra will automatically execute at scheduled time
3. Check Kestra → Executions for history

## Workflow Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Kestra (trikru)                                        │
│  ┌───────────────────────────────────────────────┐     │
│  │ KV Store                                      │     │
│  │  - GCP_SERVICE_ACCOUNT_JSON                   │     │
│  │  - SSH_PRIVATE_KEY                            │     │
│  │  - BELLAMY_HOST / USER                        │     │
│  └───────────────────────────────────────────────┘     │
│                     ↓                                   │
│  ┌───────────────────────────────────────────────┐     │
│  │ Workflow: postgres-backup-gcs-sync            │     │
│  │  1. Clone playbooks repo                      │     │
│  │  2. Inject GCP credentials                    │     │
│  │  3. SSH to bellamy, copy credentials          │     │
│  │  4. Run ansible playbook                      │     │
│  │  5. Cleanup credentials                       │     │
│  │  6. Verify uploads in GCS                     │     │
│  └───────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────┘
                            ↓
                     ┌──────────────┐
                     │  bellamy     │
                     │  /var/backup/│
                     │  postgresql/ │
                     └──────────────┘
                            ↓
                ┌────────────────────────┐
                │  GCS                   │
                │  iv3-infra-us-prod/    │
                │  postgres-backups/     │
                └────────────────────────┘
```

## Security Notes

✅ **Credentials handled securely:**

- GCP JSON stored in Kestra KV (encrypted at rest)
- Credentials copied to bellamy only during execution
- Cleaned up immediately after ansible runs
- Never stored permanently on bellamy

✅ **No secrets in code:**

- All secrets fetched from Kestra KV at runtime
- Workflow YAML contains no hardcoded credentials

## Troubleshooting

### Error: "GCP service account key not found"

**Fix:** Verify KV store entry

```bash
curl "http://trikru:8080/api/v1/namespaces/ops/kv/GCP_SERVICE_ACCOUNT_JSON"
```

### Error: "Permission denied" on bellamy

**Fix:** Ensure SSH key is correct

```bash
ssh -i ~/.ssh/id_ed25519 thein3rovert@bellamy "echo works"
```

### Error: "gsutil not found" on bellamy

**Fix:** Install google-cloud-sdk on bellamy (already in NixOS config if using GCP modules)

### Error: "Backup files not found"

**Cause:** Postgres backup hasn't run yet
**Fix:** Check if postgresqlBackup service is enabled

```bash
ssh bellamy "systemctl status postgresqlBackup.service"
ssh bellamy "ls -lh /var/backup/postgresql/"
```

## Monitoring

### View Execution History

1. Go to Kestra → Executions
2. Filter by flow: `postgres-backup-gcs-sync`
3. View success/failure rate

### Setup Alerts

Add to the workflow's `errors:` section (uncomment the notification placeholder):

```yaml
errors:
  - id: slack_alert
    type: io.kestra.plugin.notifications.slack.SlackIncomingWebhook
    url: "{{ kv('SLACK_WEBHOOK_URL') }}"
    payload: |
      {
        "text": "❌ Postgres backup sync failed!",
        "blocks": [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "*Postgres Backup Sync Failed*\n\nExecution: {{ execution.id }}\nTime: {{ execution.startDate }}"
            }
          }
        ]
      }
```

## Cost

- **Kestra execution**: Free (self-hosted)
- **GCS storage**: $0.00/month (within 5GB free tier)
- **Network**: Minimal (<1GB/month)

**Total**: $0.00/month ✅

## Next Steps

1. ✅ Add GCP_SERVICE_ACCOUNT_JSON to Kestra KV
2. ✅ Deploy workflow to Kestra
3. ✅ Run manual test
4. ✅ Verify backups in GCS
5. ⏳ Wait for scheduled run at 03:15 AM
6. 🔔 (Optional) Add Slack/email alerts

## Support

- Kestra docs: https://kestra.io/docs
- Ansible role: `roles/postgres-gcs-backup/README.md`
- GCS bucket: `gs://iv3-infra-us-prod/postgres-backups/`
