# Backup and restore

PawHelp keeps PostgreSQL in Kubernetes as code. The database is deployed by the `pawhelp-postgres` Helm chart.

## Backup layers

### 1. PostgreSQL logical backup

The chart creates a Kubernetes `CronJob`:

```text
<release>-postgres-backup
```

Default schedule:

```text
0 2 * * *
```

Backup files are written as custom-format dumps:

```text
/backups/<database>/<database>-YYYYMMDDTHHMMSSZ.dump
```

The backup PVC is:

```text
<release>-postgres-backups
```

Retention:

```text
dev: 3 days
prod: 14 days
```

### 2. EBS snapshots

Terraform creates an AWS DLM lifecycle policy for EC2 node EBS volumes tagged with:

```text
Project=pawhelp
Environment=<dev|prod>
Backup=true
```

Defaults:

```text
dev: every 24h, keep 3 snapshots
prod: every 24h, keep 7 snapshots
```

This protects node disks. PostgreSQL logical dumps are still the primary database recovery path.

## Manual backup

```powershell
kubectl -n pawhelp-dev create job --from=cronjob/pawhelp-postgres-backup manual-postgres-backup
kubectl -n pawhelp-dev logs job/manual-postgres-backup
```

## Restore flow

1. Scale backend down so writes stop.
2. Copy the selected dump into a temporary pod with PostgreSQL client.
3. Restore with `pg_restore`.
4. Restart backend.

Example:

```bash
pg_restore -h pawhelp-postgres -U pawhelp -d pawhelp --clean --if-exists /backups/pawhelp/pawhelp-YYYYMMDDTHHMMSSZ.dump
```

## Paths

```text
PostgreSQL data: /var/lib/postgresql/data/pgdata
PostgreSQL backups: /backups/<database>/*.dump
Terraform DLM policy: terraform/aws-k3s/main.tf
Helm backup CronJob: helm/pawhelp-postgres/templates/backup-cronjob.yaml
```

## Notes

- Backup PVC lives in Kubernetes and is suitable for demo and short-lived environments.
- For longer-lived production, sync dumps to S3 with a dedicated backup image or external backup controller.
- Do not rely only on EBS snapshots for PostgreSQL restore. Use logical dumps for application-level recovery.