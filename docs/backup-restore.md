# Backup and restore

PostgreSQL runs inside Kubernetes. Backups have two layers:

1. Logical dumps with `pg_dump -Fc` from the `pawhelp-postgres-backup` CronJob.
2. AWS EBS snapshots for Kubernetes node volumes through Terraform DLM policy.

## S3 export

Terraform creates one S3 bucket per environment:

```text
pawhelp-<env>-postgres-backups-<aws-account-id>-<aws-region>
```

Terraform also writes these SSM parameters:

```text
/pawhelp/dev/postgres-backup/S3_BUCKET
/pawhelp/dev/postgres-backup/S3_PREFIX
/pawhelp/dev/postgres-backup/AWS_REGION

/pawhelp/prod/postgres-backup/S3_BUCKET
/pawhelp/prod/postgres-backup/S3_PREFIX
/pawhelp/prod/postgres-backup/AWS_REGION
```

External Secrets Operator syncs those values into the Kubernetes secret used by the backup CronJob. The CronJob writes dumps to:

```text
PVC path: /backups/<database>/*.dump
S3 path: s3://<bucket>/<prefix>/<database>-<timestamp>.dump
```

## Manual backup

```bash
kubectl -n pawhelp-dev create job --from=cronjob/pawhelp-postgres-backup manual-postgres-backup
kubectl -n pawhelp-dev logs job/manual-postgres-backup -f
```

## Restore from S3

```bash
aws s3 cp s3://<bucket>/<prefix>/<dump-file>.dump ./restore.dump
kubectl -n pawhelp-dev cp ./restore.dump pawhelp-postgres-0:/tmp/restore.dump
kubectl -n pawhelp-dev exec -it pawhelp-postgres-0 -- pg_restore -U pawhelp -d pawhelp --clean --if-exists /tmp/restore.dump
```

## Terraform paths

```text
terraform/aws-k3s/backups.tf       S3 bucket, lifecycle, SSM paths, IAM access
terraform/aws-k3s/main.tf          EBS volume tags and DLM snapshots
helm/pawhelp-postgres/templates/   backup CronJob, PVC, S3 ExternalSecret
```

EBS snapshots are useful for node-level recovery, but application recovery should use the logical PostgreSQL dump first.
