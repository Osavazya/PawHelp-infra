# Secrets

Real secret values must not be committed. Runtime application secrets are read from AWS SSM Parameter Store by External Secrets Operator.

## AWS and Terraform

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_REGION
TF_STATE_BUCKET
```

## TeamCity secure parameters

```text
aws.account.id
aws.region
github.token
argocd.server
argocd.username
argocd.password
```

Optional if the TeamCity agent does not use an instance profile:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

## Runtime SSM values

Seed these before Argo syncs the application:

```bash
aws ssm put-parameter --name /pawhelp/dev/postgres/POSTGRES_DB --type String --value pawhelp --overwrite
aws ssm put-parameter --name /pawhelp/dev/postgres/POSTGRES_USER --type String --value pawhelp --overwrite
aws ssm put-parameter --name /pawhelp/dev/postgres/POSTGRES_PASSWORD --type SecureString --value '<dev-password>' --overwrite
aws ssm put-parameter --name /pawhelp/dev/backend/SECRET_KEY --type SecureString --value '<dev-secret>' --overwrite
aws ssm put-parameter --name /pawhelp/dev/backend/DATABASE_URL --type SecureString --value 'postgresql://pawhelp:<dev-password>@pawhelp-postgres:5432/pawhelp' --overwrite
aws ssm put-parameter --name /pawhelp/dev/backend/GOOGLE_MAPS_API_KEY --type SecureString --value '<key-or-empty>' --overwrite
```

Repeat the same paths under `/pawhelp/prod/...` for production.

Terraform writes the PostgreSQL backup S3 parameters automatically:

```text
/pawhelp/<env>/postgres-backup/S3_BUCKET
/pawhelp/<env>/postgres-backup/S3_PREFIX
/pawhelp/<env>/postgres-backup/AWS_REGION
```
