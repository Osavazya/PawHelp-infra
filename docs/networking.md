# Networking and access model

## AWS network

The default AWS stack is designed for a short-lived low-cost demo:

- one VPC per environment;
- public subnets for all k3s nodes;
- no NAT Gateway;
- no AWS Load Balancer;
- one Elastic IP attached to the control-plane node;
- node-to-node traffic is allowed only inside the Kubernetes security group;
- public ingress is limited to TCP 80 and 443;
- SSH and Kubernetes API are closed unless `admin_cidr_blocks` is set.

## Stable entry point

Terraform creates one Elastic IP:

```text
terraform output control_plane_eip
```

The control-plane bootstrap script associates that EIP with the current control-plane EC2 instance. If the ASG replaces the instance, the new node re-associates the same EIP.

## Internal services

These services are Kubernetes `ClusterIP` by default:

```text
backend
frontend
postgres
libretranslate
crm-manager
prometheus
grafana
loki
teamcity
argocd
```

Prometheus, Grafana, Loki, TeamCity, and Argo CD are deployed only in dev.

External access is only through k3s Traefik ingress and the node security group.

## Admin-only services

Argo CD is installed in dev and exposed only through the internal VPN allowlist. TeamCity and Grafana follow the same model.

Prod does not host Argo CD or TeamCity. Register the prod cluster in dev Argo CD as `pawhelp-prod` and deploy prod from there.

## Production upgrade path

For a real always-on production cluster, replace the demo network with:

- private worker subnets;
- public ingress subnets;
- NAT Gateway or VPC endpoints;
- AWS Load Balancer Controller;
- Route 53 records;
- ACM certificates;
- in-cluster PostgreSQL with tested backups and restore runbooks;
- S3 for backend uploads.

## Internal platform access

Application ingress can stay public. Platform UIs are internal-only:

```text
Argo CD
Grafana
TeamCity
```

Terraform installs WireGuard on the control-plane node and opens only the WireGuard UDP port. Traefik middleware allows platform ingress traffic only from the VPN CIDR. See `docs/internal-access.md`.

## Worker node pools

Dev creates separate worker ASGs for frontend, backend, and infra. Prod creates frontend and backend worker ASGs only. Workloads are pinned with Kubernetes `nodeSelector`; dev infra workloads also tolerate the infra taint. This keeps application workloads away from the control-plane and avoids running CI/CD or observability infrastructure inside prod.