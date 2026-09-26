# Internal access

The public application ingress stays reachable on HTTP/HTTPS. Infrastructure UIs are internal-only and require WireGuard VPN access.

## What is public

```text
https://dev.pawhelp.localhost
https://api.dev.pawhelp.localhost
https://pawhelp.localhost
https://api.pawhelp.localhost
```

## What is internal

```text
https://argocd.dev.pawhelp.internal
https://grafana.dev.pawhelp.internal
https://teamcity.pawhelp.internal

https://argocd.prod.pawhelp.internal
https://grafana.prod.pawhelp.internal
```

These ingresses use Traefik `ipAllowList` middleware. Requests are allowed only from the VPN CIDR:

```text
dev:  10.44.0.0/24
prod: 10.45.0.0/24
```

## WireGuard bootstrap

Terraform installs WireGuard on the control-plane node when `enable_wireguard = true`.

Terraform outputs:

```text
wireguard_endpoint
wireguard_server_address
```

Terraform also writes SSM parameters:

```text
/pawhelp/dev/k3s/wireguard/server_public_key
/pawhelp/dev/k3s/wireguard/endpoint
/pawhelp/dev/k3s/wireguard/server_address

/pawhelp/prod/k3s/wireguard/server_public_key
/pawhelp/prod/k3s/wireguard/endpoint
/pawhelp/prod/k3s/wireguard/server_address
```

## Add a client peer

Generate a client key on your workstation:

```bash
wg genkey | tee client.key | wg pubkey > client.pub
```

Add the public key to the environment tfvars:

```hcl
wireguard_peers = [
  {
    name        = "admin-laptop"
    public_key  = "<client-public-key>"
    allowed_ips = "10.44.0.10/32"
  }
]
```

For prod, use a `10.45.0.0/24` address.

Client config example:

```ini
[Interface]
PrivateKey = <client-private-key>
Address = 10.44.0.10/32
DNS = 1.1.1.1

[Peer]
PublicKey = <server-public-key-from-ssm>
Endpoint = <wireguard-endpoint-from-terraform>
AllowedIPs = 10.44.0.1/32
PersistentKeepalive = 25
```

Add local host records after connecting to VPN:

```text
10.44.0.1 argocd.dev.pawhelp.internal grafana.dev.pawhelp.internal teamcity.pawhelp.internal
10.45.0.1 argocd.prod.pawhelp.internal grafana.prod.pawhelp.internal
```

This keeps Argo CD, Grafana, and TeamCity off the public internet while avoiding paid AWS Client VPN for the portfolio environment.

## Node placement

The control-plane node is tainted with `node-role.kubernetes.io/control-plane=true:NoSchedule`.

Worker node pools use this label:

```text
pawhelp.io/node-pool=frontend
pawhelp.io/node-pool=backend
pawhelp.io/node-pool=infra
```

The infra pool is tainted:

```text
pawhelp.io/node-pool=infra:NoSchedule
```

Argo CD, Grafana, cert-manager, External Secrets, and TeamCity tolerate that taint and use `nodeSelector` for the infra pool. TeamCity is present only in the dev Argo root.