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

External access is only through k3s Traefik ingress and the node security group.

## Admin-only services

Argo CD is installed inside the cluster and is not exposed by default. Use port-forward or SSM session for administration:

```powershell
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

TeamCity has an ingress host for demo access, but the service still lives in Kubernetes and can be restricted by DNS/security group rules in a real deployment.

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