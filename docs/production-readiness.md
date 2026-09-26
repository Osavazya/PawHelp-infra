# Production readiness checklist

## Already covered

- Separate backend, frontend, and infra repositories.
- `master` and `prod` branches.
- Terraform remote state bucket bootstrap.
- AWS VPC, subnets, routes, security group, IAM, EC2 ASG.
- Dev k3s cluster with 1 control-plane and 3 workers: frontend, backend, infra.
- Prod k3s cluster with 1 control-plane and 2 workers: frontend, backend.
- Elastic IP for the control-plane entry point.
- Argo CD app-of-apps.
- Helm umbrella chart and service charts.
- External Secrets Operator with AWS SSM Parameter Store.
- Vault in dev for internal secret workflows.
- cert-manager for in-cluster certificates.
- Prometheus, Grafana, Loki, Promtail through Helm.
- TeamCity server and build agent through Helm.
- TeamCity Kotlin DSL for validate, build, deploy, regression.
- PostgreSQL logical backup export to S3.
- EBS snapshot policy for node volumes.
- Resource requests and limits for application workloads.
- PodDisruptionBudget for backend/frontend.
- HPA for stateless frontend.
- NetworkPolicy for backend ingress.
- Secret path documentation.
- CRM manager workload in Kubernetes.

## Known constraints

- Backend uploads use a `ReadWriteOnce` PVC, so backend stays at 1 replica until uploads move to S3.
- PostgreSQL is deployed in-cluster by Helm. Backups, restore flow, resource limits, and upgrade discipline are required for this model.
- k3s default flannel does not enforce NetworkPolicy by itself. Use Calico or Cilium if NetworkPolicy enforcement is required.
- TeamCity image builds require a Docker-capable agent or a Kaniko/BuildKit-based build runner.
- The current AWS topology avoids ALB, NAT Gateway, external database services, and managed Kubernetes to keep infrastructure cost controlled.

## Recommended next steps

1. Keep Terraform-managed ECR image tags immutable.
2. Move backend uploads to S3.
3. Add Route 53 and ACM certificates for public DNS.
4. Add database restore automation tests.
5. Add API regression tests and mobile smoke tests.
6. Add Trivy image scanning enforcement to TeamCity.
7. Add Terraform plan approval for prod.
8. Add Argo CD RBAC and SSO.
9. Add SLO dashboards and alert routes.