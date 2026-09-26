# CI/CD flow

TeamCity is configured as code in `teamcity/settings.kts`.

## Build flow

```text
backend repo   -> tests -> image build -> ghcr.io/osavazya/pawhelp-backend:<git-sha>
frontend repo  -> lint/export -> image build -> ghcr.io/osavazya/pawhelp-frontend:<git-sha>
infra repo     -> Helm values image tag update -> Argo CD sync -> regression checks
```

## Required TeamCity secure parameters

```text
ghcr.username
ghcr.token
github.token
argocd.server
argocd.username
argocd.password
backend.image.tag
frontend.image.tag
```

`backend.image.tag` and `frontend.image.tag` are explicit deploy inputs. This keeps promotion controlled: the same image can be promoted from dev to prod without rebuilding it.

## Dev deployment

The `deploy dev` build type updates:

```text
helm/pawhelp/values-dev.yaml
```

Then it commits `Bump images`, pushes to `master`, and asks Argo CD to sync `pawhelp-dev`.

## Regression

The `regression dev` build type checks:

```text
http://api.dev.pawhelp.localhost/health
http://dev.pawhelp.localhost/healthz
http://crm.dev.pawhelp.localhost/
```

In a real pipeline, extend this with API contract tests, login flow checks, and mobile smoke tests.

## Registry

The default registry is GHCR:

```text
ghcr.io/osavazya/pawhelp-backend
ghcr.io/osavazya/pawhelp-frontend
```

For AWS-native production, add ECR repositories and change image repositories in Helm values.