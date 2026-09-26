# PawHelp Infrastructure

Infrastructure code for PawHelp with separate provisioning, delivery, observability, and CI/CD layers.

## Platform documentation

- [Deployment flow](docs/deployment-flow.md)
- [Secret paths](docs/secret-paths.md)
- [Local endpoints](docs/local-endpoints.md)
- [Secrets checklist](docs/secrets.md)
- [Production readiness](docs/production-readiness.md)
- [Backup and restore](docs/backup-restore.md)
- [CI/CD flow](docs/cicd.md)
- [Networking](docs/networking.md)
- [Internal access](docs/internal-access.md)

## Runtime services

```text
pawhelp-dev / pawhelp-prod       Backend, frontend, PostgreSQL, LibreTranslate
crm-dev / crm-prod               CRM manager workspace and Excel import storage
monitoring-dev                   Prometheus, Grafana, Loki, Promtail, Vault
teamcity                         TeamCity server and build agent
```

## What is included

- Terraform bootstrap for encrypted S3 remote state.
- Terraform AWS stack with VPC, public subnets, internet routing, security groups, IAM, Elastic IP, artifact S3 bucket, PostgreSQL backup S3 bucket, ECR repositories, EC2 launch templates, and ASGs.
- Dev Kubernetes cluster: 1 tainted control-plane node and 3 worker node pools: frontend, backend, and infra.
- Prod Kubernetes cluster: 1 tainted control-plane node and 2 worker node pools: frontend and backend.
- k3s bootstrap through EC2 user data, with cluster join data stored in SSM Parameter Store.
- Shared Argo CD app-of-apps in dev for dev and prod delivery.
- Helm umbrella chart for PawHelp backend, frontend, PostgreSQL, and LibreTranslate.
- Helm charts for cert-manager, External Secrets Operator, Prometheus, Grafana, Loki, Promtail, Vault, alerting rules, and dashboards.
- Helm chart for TeamCity server and agent, deployed only from the dev Argo root.
- Helm chart for CRM manager workspace.
- Resource requests, limits, namespace quotas, PDB, HPA, and NetworkPolicy for application workloads.
- TeamCity pipeline-as-code for test, image build, ECR push, GitOps image tag bump, Argo CD sync, and regression checks.
- WireGuard VPN bootstrap and Traefik allowlist middleware for internal Argo CD, Grafana, Vault, and TeamCity access.
- Optional Ansible k3s playbook for manual bootstrap.

## Node pool placement

```text
control-plane  k3s API and bootstrap only, tainted NoSchedule
frontend       frontend web workload
backend        API, PostgreSQL, LibreTranslate, backup CronJobs
infra          dev only: Argo CD, TeamCity, Vault, cert-manager, External Secrets, monitoring
```

Prod does not deploy TeamCity, Argo CD, Vault, Grafana, or a dedicated infra worker. Prod cluster add-ons run on the backend worker pool.

## AWS cost profile

The topology intentionally avoids EKS, NAT Gateway, external database services, and managed load balancers. Dev creates 4 EC2 instances, prod creates 3 EC2 instances.

## Directory layout

```text
terraform/
    bootstrap/
    aws-k3s/
ansible/
    k3s/
argocd/
    projects/
    applications/
helm/
    pawhelp/
    pawhelp-backend/
    pawhelp-frontend/
    pawhelp-postgres/
    libretranslate/
    monitoring/
    platform/
    teamcity/
```

## Bootstrap Terraform state

```powershell
cd terraform/bootstrap
terraform init
terraform apply -var="project=pawhelp" -var="aws_region=eu-central-1"
```

Copy the `state_bucket` output into:

- `terraform/aws-k3s/backend-dev.hcl`
- `terraform/aws-k3s/backend-prod.hcl`

## Create a Kubernetes environment

```powershell
cd terraform/aws-k3s
terraform init -backend-config=backend-dev.hcl
terraform apply -var-file=env/dev.tfvars
```

For prod:

```powershell
terraform init -reconfigure -backend-config=backend-prod.hcl
terraform apply -var-file=env/prod.tfvars
```

Dev has `enable_argocd = true`. Prod has `enable_argocd = false`; prod deployments are managed by the dev Argo CD after the prod cluster is registered as `pawhelp-prod`.

## Destroy

```powershell
cd terraform/aws-k3s
terraform init -reconfigure -backend-config=backend-dev.hcl
terraform destroy -var-file=env/dev.tfvars
terraform init -reconfigure -backend-config=backend-prod.hcl
terraform destroy -var-file=env/prod.tfvars
```

## Helm validation

```powershell
cd helm/pawhelp
helm dependency build
helm lint . -f values-dev.yaml

cd ../monitoring
helm dependency build
helm lint . -f values-dev.yaml
```

## Argo CD

Register prod in the dev Argo CD as `pawhelp-prod`, then sync `pawhelp-prod-root`. TeamCity changes image tags in Git; Argo CD applies those changes to the target cluster.