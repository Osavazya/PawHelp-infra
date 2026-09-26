# Production readiness checklist

## Already covered

- Separate backend, frontend, and infra repositories.
- `master` and `prod` branches.
- Terraform remote state bucket bootstrap.
- AWS VPC, subnets, routes, security group, IAM, EC2 ASG.
- k3s with 1 control-plane and 2 workers per environment.
- Elastic IP for the control-plane entry point.
- Argo CD app-of-apps.
- Helm umbrella chart and service charts.
- Prometheus, Grafana, Loki, Promtail through Helm.
- TeamCity server and build agent through Helm.
- TeamCity Kotlin DSL for validate, build, deploy, regression.
- Resource requests and limits for application workloads.
- PodDisruptionBudget for backend/frontend.
- HPA for stateless frontend.
- NetworkPolicy for backend ingress.
- Secret path documentation.
- CRM manager workload in Kubernetes.

## Important limitations

- Backend uploads use a `ReadWriteOnce` PVC, so backend stays at 1 replica. Move uploads to S3 before scaling backend horizontally.
- PostgreSQL is deployed in-cluster for demo purposes. Use RDS or an external managed PostgreSQL service for real production.
- k3s default flannel does not enforce NetworkPolicy by itself. Use Calico/Cilium if NetworkPolicy enforcement is required.
- TeamCity image builds require a Docker-capable agent or a Kaniko/BuildKit-based build runner.
- The demo avoids ALB/NAT/RDS to keep AWS cost low. Real production should use private subnets and managed ingress.

## Recommended next steps

1. Add ECR repositories or keep GHCR public/private with image pull secrets.
2. Add External Secrets Operator and map AWS SSM paths to Kubernetes Secrets.
3. Add cert-manager and ACM/Route 53 for real DNS.
4. Move backend uploads to S3.
5. Add database backups and restore runbooks.
6. Add API regression tests and mobile smoke tests.
7. Add Trivy image scanning to TeamCity.
8. Add Terraform plan approval for prod.
9. Add Argo CD RBAC and SSO.
10. Add SLO dashboards and alert routes.