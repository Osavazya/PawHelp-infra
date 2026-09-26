# PawHelp Infrastructure

Production-style infrastructure for PawHelp with separate provisioning and delivery layers.


## Platform documentation

- [Deployment flow](docs/deployment-flow.md)
- [Secret paths](docs/secret-paths.md)
- [Local endpoints](docs/local-endpoints.md)
- [Secrets checklist](docs/secrets.md)
- [Production readiness](docs/production-readiness.md)
- [CI/CD flow](docs/cicd.md)
- [Networking](docs/networking.md)

## Runtime services

```text
pawhelp-dev / pawhelp-prod       Backend, frontend, PostgreSQL, LibreTranslate
crm-dev / crm-prod               CRM manager workspace and Excel import storage
monitoring-dev / monitoring-prod Prometheus, Grafana, Loki, Promtail
teamcity                         TeamCity server and build agent
```
## What is included

- Terraform bootstrap for encrypted S3 remote state.
- Terraform AWS stack with VPC, public subnets, internet routing, security groups, IAM, Elastic IP, artifact S3 bucket, EC2 launch templates, and ASGs.
- One Kubernetes cluster per environment: 1 control-plane node and 2 worker nodes.
- k3s bootstrap through EC2 user data, with cluster join data stored in SSM Parameter Store.
- Argo CD app-of-apps for application delivery.
- Helm umbrella chart for PawHelp backend, frontend, PostgreSQL, and LibreTranslate.
- Helm charts for Prometheus, Grafana, Loki, Promtail, alerting rules, and dashboards.
- Helm chart for TeamCity server and agent.
- Helm chart for CRM manager workspace.
- Resource requests, limits, PDB, HPA, and NetworkPolicy for application workloads.
- TeamCity pipeline-as-code for test, image build, image push, Argo CD sync, and regression checks.
- Optional Ansible k3s playbook for manual bootstrap or interview demo.

## AWS cost model

The default topology intentionally avoids EKS, NAT Gateway, RDS, and managed load balancers. The stack still creates 3 EC2 instances per environment because the target is a DevOps portfolio-grade Kubernetes layout. Apply it, verify, and destroy it when done.

## Directory layout

```text
infra/
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
    teamcity/
```

## Bootstrap Terraform state

```powershell
cd D:\PawHelp\infra\terraform\bootstrap
terraform init
terraform apply -var="project=pawhelp" -var="aws_region=eu-central-1"
```

Copy the `state_bucket` output into:

- `infra/terraform/aws-k3s/backend-dev.hcl`
- `infra/terraform/aws-k3s/backend-prod.hcl`

## Create a Kubernetes environment

```powershell
cd D:\PawHelp\infra\terraform\aws-k3s
terraform init -backend-config=backend-dev.hcl
terraform apply -var-file=env/dev.tfvars
```

For prod:

```powershell
terraform init -reconfigure -backend-config=backend-prod.hcl
terraform apply -var-file=env/prod.tfvars
```

Set `git_repo_url` in the tfvars file before apply if Argo CD should bootstrap itself from this repository.

## Destroy

```powershell
cd D:\PawHelp\infra\terraform\aws-k3s
terraform init -reconfigure -backend-config=backend-dev.hcl
terraform destroy -var-file=env/dev.tfvars
terraform init -reconfigure -backend-config=backend-prod.hcl
terraform destroy -var-file=env/prod.tfvars
```

## Helm validation

```powershell
cd D:\PawHelp\infra\helm\pawhelp
helm dependency build
helm lint . -f values-dev.yaml

cd D:\PawHelp\infra\helm\monitoring
helm dependency build
helm lint . -f values-dev.yaml
```

## Argo CD

Replace `https://github.com/Osavazya/PawHelp-infra.git` in `infra/argocd/applications/*.yaml` with the real repo URL.
