# Secret paths

Real secret values must not be committed. The repository stores only names and paths.

## AWS SSM Parameter Store

### PostgreSQL

```text
/pawhelp/dev/postgres/POSTGRES_DB
/pawhelp/dev/postgres/POSTGRES_USER
/pawhelp/dev/postgres/POSTGRES_PASSWORD

/pawhelp/prod/postgres/POSTGRES_DB
/pawhelp/prod/postgres/POSTGRES_USER
/pawhelp/prod/postgres/POSTGRES_PASSWORD
```

### Backend

```text
/pawhelp/dev/backend/SECRET_KEY
/pawhelp/dev/backend/DATABASE_URL
/pawhelp/dev/backend/GOOGLE_MAPS_API_KEY

/pawhelp/prod/backend/SECRET_KEY
/pawhelp/prod/backend/DATABASE_URL
/pawhelp/prod/backend/GOOGLE_MAPS_API_KEY
```

### PostgreSQL backup export

Terraform creates these values:

```text
/pawhelp/dev/postgres-backup/S3_BUCKET
/pawhelp/dev/postgres-backup/S3_PREFIX
/pawhelp/dev/postgres-backup/AWS_REGION

/pawhelp/prod/postgres-backup/S3_BUCKET
/pawhelp/prod/postgres-backup/S3_PREFIX
/pawhelp/prod/postgres-backup/AWS_REGION
```

### CRM manager

```text
/pawhelp/dev/crm/DATABASE_URL
/pawhelp/dev/crm/JWT_SECRET
/pawhelp/dev/crm/EXCEL_IMPORT_TOKEN
/pawhelp/dev/crm/NOTIFICATION_WEBHOOK_URL

/pawhelp/prod/crm/DATABASE_URL
/pawhelp/prod/crm/JWT_SECRET
/pawhelp/prod/crm/EXCEL_IMPORT_TOKEN
/pawhelp/prod/crm/NOTIFICATION_WEBHOOK_URL
```

## Kubernetes Secret names

```text
pawhelp-pawhelp-backend
pawhelp-postgres
pawhelp-postgres-backup-s3
crm-manager-crm-manager
```

## Local paths inside pods

```text
Backend uploads: /app/uploads
CRM Excel imports: /data/imports
CRM exports: /data/exports
CRM reports: /data/reports
PostgreSQL data: /var/lib/postgresql/data/pgdata
PostgreSQL backup PVC: /backups/<database>
PostgreSQL backup S3: s3://<bucket>/<prefix>
```
