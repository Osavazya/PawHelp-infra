# Deployment flow

```text
Backend repo   -> TeamCity -> ECR pawhelp-backend:<sha>
Frontend repo  -> TeamCity -> ECR pawhelp-frontend:<sha>
Infra repo     -> Argo CD  -> Helm release in Kubernetes
```

Terraform is used for infrastructure lifecycle. Helm and Argo CD are used for application lifecycle.

## Dev path

```text
branch: master
terraform: terraform/aws-k3s/env/dev.tfvars
app values: helm/pawhelp/values-dev.yaml
monitoring values: helm/monitoring/values-dev.yaml
crm values: helm/crm-manager/values-dev.yaml
namespace: pawhelp-dev, monitoring-dev, crm-dev
```

## Prod path

```text
branch: prod
terraform: terraform/aws-k3s/env/prod.tfvars
app values: helm/pawhelp/values-prod.yaml
monitoring values: helm/monitoring/values-prod.yaml
crm values: helm/crm-manager/values-prod.yaml
namespace: pawhelp-prod, monitoring-prod, crm-prod
```

## CRM manager

CRM manager is deployed as an internal Kubernetes service with persistent paths for Excel imports, exports, and reports. The chart is intentionally isolated from the public app chart because it is an operator tool.