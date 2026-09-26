# Secrets

Real secret values must not be committed.

Runtime application secrets are synced into Kubernetes by External Secrets Operator. The default backend is AWS SSM Parameter Store. Dev also installs Vault and exposes a `vault` ClusterSecretStore for teams that want to move selected secrets to Vault later.

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

`github.token` is a TeamCity secure parameter. It should be a fine-scoped token owned by a GitHub bot or technical user with push access to `PawHelp-infra`, not a personal token committed to Git.

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

## Vault

Vault is installed only in dev on the infra worker. It is reachable through VPN as:

```text
https://vault.dev.pawhelp.internal
```

The `vault` ClusterSecretStore expects this Kubernetes secret in `platform-system`:

```bash
kubectl -n platform-system create secret generic vault-token --from-literal=token='<vault-token>'
```

Do not commit Vault root tokens or unseal keys.