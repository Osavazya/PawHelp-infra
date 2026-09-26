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
```

These ingresses use Traefik `ipAllowList` middleware. Requests are allowed only from the dev VPN CIDR:

```text
dev: 10.44.0.0/24
```

Prod has no internal UI stack. WireGuard can still be enabled on the prod control-plane for admin access to the node and Kubernetes API path, but application delivery is controlled from dev Argo CD.

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

Add local host records after connecting to the dev VPN:

```text
10.44.0.1 argocd.dev.pawhelp.internal grafana.dev.pawhelp.internal teamcity.pawhelp.internal
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

The infra pool exists only in dev and is tainted:

```text
pawhelp.io/node-pool=infra:NoSchedule
```

Dev infrastructure workloads tolerate that taint and use `nodeSelector` for the infra pool. Prod does not create an infra pool; prod platform add-ons run on the backend worker pool.