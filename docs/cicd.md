# CI/CD flow

TeamCity is configured as code in `teamcity/settings.kts`.

## Build flow

```text
backend repo   -> tests -> docker build -> optional Trivy scan -> ECR push
frontend repo  -> lint/export -> docker build -> optional Trivy scan -> ECR push
infra repo     -> Helm values image repository/tag update -> git push -> Argo CD autosync -> smoke regression
```

## Registry

Terraform creates AWS ECR repositories:

```text
pawhelp-backend
pawhelp-frontend
```

TeamCity builds immutable image tags from the source commit SHA and pushes:

```text
<aws-account-id>.dkr.ecr.<aws-region>.amazonaws.com/pawhelp-backend:<git-sha>
<aws-account-id>.dkr.ecr.<aws-region>.amazonaws.com/pawhelp-frontend:<git-sha>
```

## GitOps deploy

The `deploy dev` build type updates this file:

```text
helm/pawhelp/values-dev.yaml
```

It changes both image repository and image tag, commits `Bump images`, pushes to `master`, and waits for Argo CD to sync `pawhelp-dev`.

## Required TeamCity secure parameters

```text
aws.account.id
aws.region
github.token
argocd.server
argocd.username
argocd.password
```

The TeamCity agent also needs AWS credentials with ECR push access. Use an instance profile, environment credentials, or TeamCity secure parameters mapped to `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.

## Quality gates

```text
infra validate: terraform fmt/init/validate, helm dependency build, helm lint
backend: compile/tests, docker build, optional Trivy scan, ECR push
frontend: npm ci, lint, Expo web export, docker build, optional Trivy scan, ECR push
deploy: GitOps tag bump, Argo health wait
regression: HTTPS smoke checks for API, frontend, CRM
```
