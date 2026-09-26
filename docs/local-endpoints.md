# Local endpoints

The demo application ingress hosts use `localhost` domains. Browsers resolve `*.localhost` to the local machine, so no public DNS is required for a local or temporary AWS demo with port forwarding.

Infrastructure UIs use `.internal` hostnames and require WireGuard VPN access. See `docs/internal-access.md`.

## Dev

```text
Frontend: https://dev.pawhelp.localhost
Backend API: https://api.dev.pawhelp.localhost
CRM manager: https://crm.dev.pawhelp.localhost
Argo CD: https://argocd.dev.pawhelp.internal
Grafana: https://grafana.dev.pawhelp.internal
TeamCity: https://teamcity.pawhelp.internal
```

## Prod demo

```text
Frontend: https://pawhelp.localhost
Backend API: https://api.pawhelp.localhost
CRM manager: https://crm.pawhelp.localhost
Argo CD: https://argocd.prod.pawhelp.internal
Grafana: https://grafana.prod.pawhelp.internal
TeamCity: https://teamcity.pawhelp.internal
```

## Access model

- Terraform creates AWS infrastructure and k3s nodes.
- Argo CD syncs Helm charts into Kubernetes.
- Public application ingress is handled by the default k3s Traefik controller.
- Internal platform ingress is protected by Traefik `ipAllowList` and WireGuard VPN CIDRs.
- For real production DNS, replace the `*.localhost` and `*.internal` hosts in Helm values with Route 53 records.
