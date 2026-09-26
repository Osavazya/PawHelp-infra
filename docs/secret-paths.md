# Secret paths

Real secret values must not be committed. The repository stores only names and paths.

## AWS SSM Parameter Store

Use these paths for runtime secrets. Keep the same path shape for dev and prod.

### Backend

```text
/pawhelp/dev/backend/SECRET_KEY
/pawhelp/dev/backend/DATABASE_URL
/pawhelp/dev/backend/POSTGRES_PASSWORD
/pawhelp/dev/backend/GOOGLE_MAPS_API_KEY
/pawhelp/dev/backend/LIBRETRANSLATE_API_KEY

/pawhelp/prod/backend/SECRET_KEY
/pawhelp/prod/backend/DATABASE_URL
/pawhelp/prod/backend/POSTGRES_PASSWORD
/pawhelp/prod/backend/GOOGLE_MAPS_API_KEY
/pawhelp/prod/backend/LIBRETRANSLATE_API_KEY
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

### Argo CD

```text
/pawhelp/dev/argocd/ADMIN_PASSWORD
/pawhelp/dev/argocd/REPO_TOKEN
/pawhelp/prod/argocd/ADMIN_PASSWORD
/pawhelp/prod/argocd/REPO_TOKEN
```

### TeamCity

```text
/pawhelp/dev/teamcity/ADMIN_PASSWORD
/pawhelp/dev/teamcity/GHCR_TOKEN
/pawhelp/prod/teamcity/ADMIN_PASSWORD
/pawhelp/prod/teamcity/GHCR_TOKEN
```

## GitHub Actions or TeamCity secure parameters

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION
GHCR_USERNAME
GHCR_TOKEN
TF_STATE_BUCKET
```

## Kubernetes Secret names

```text
pawhelp-pawhelp-backend
pawhelp-postgres
crm-manager-crm-manager
```

## Local file paths inside pods

```text
Backend uploads: /app/uploads
CRM Excel imports: /data/imports
CRM exports: /data/exports
CRM reports: /data/reports
PostgreSQL data: /var/lib/postgresql/data/pgdata
```