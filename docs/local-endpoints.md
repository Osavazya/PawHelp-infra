# Local endpoints

The demo ingress hosts use `localhost` domains. Browsers resolve `*.localhost` to the local machine, so no public DNS is required for a local or temporary AWS demo with port forwarding.

## Dev

```text
Frontend: http://dev.pawhelp.localhost
Backend API: http://api.dev.pawhelp.localhost
CRM manager: http://crm.dev.pawhelp.localhost
Grafana: http://grafana.dev.pawhelp.localhost
```

## Prod demo

```text
Frontend: http://pawhelp.localhost
Backend API: http://api.pawhelp.localhost
CRM manager: http://crm.pawhelp.localhost
Grafana: http://grafana.pawhelp.localhost
TeamCity: http://teamcity.pawhelp.localhost
```

## Access model

- Terraform creates AWS infrastructure and k3s nodes.
- Argo CD syncs Helm charts into Kubernetes.
- Ingress is handled by the default k3s Traefik controller.
- For real production DNS, replace the `*.localhost` hosts in Helm values with Route 53 records.