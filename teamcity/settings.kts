import jetbrains.buildServer.configs.kotlin.BuildType
import jetbrains.buildServer.configs.kotlin.FailureAction
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.dependencies.snapshot
import jetbrains.buildServer.configs.kotlin.project
import jetbrains.buildServer.configs.kotlin.triggers.vcs
import jetbrains.buildServer.configs.kotlin.vcs.GitVcsRoot
import jetbrains.buildServer.configs.kotlin.version

version = "2024.12"

project {
    vcsRoot(InfraRepo)
    vcsRoot(BackendRepo)
    vcsRoot(FrontendRepo)

    buildType(InfraValidate)
    buildType(BuildBackendImage)
    buildType(BuildFrontendImage)
    buildType(DeployDev)
    buildType(RegressionDev)
}

object InfraRepo : GitVcsRoot({
    name = "PawHelp infra"
    url = "https://github.com/Osavazya/PawHelp-infra.git"
    branch = "refs/heads/master"
})

object BackendRepo : GitVcsRoot({
    name = "PawHelp backend"
    url = "https://github.com/Osavazya/PawHelp-backend.git"
    branch = "refs/heads/master"
})

object FrontendRepo : GitVcsRoot({
    name = "PawHelp frontend"
    url = "https://github.com/Osavazya/PawHelp-frontend.git"
    branch = "refs/heads/master"
})

object InfraValidate : BuildType({
    id("InfraValidate")
    name = "infra validate"
    vcs { root(InfraRepo) }
    steps {
        script {
            name = "terraform validate"
            scriptContent = """
                cd terraform/aws-k3s
                terraform fmt -check -recursive
                terraform init -backend=false
                terraform validate
            """.trimIndent()
        }
        script {
            name = "helm lint"
            scriptContent = """
                helm dependency build helm/platform
                helm dependency build helm/monitoring
                helm dependency update helm/pawhelp
                helm lint helm/platform -f helm/platform/values.yaml
                helm lint helm/pawhelp -f helm/pawhelp/values-dev.yaml
                helm lint helm/pawhelp -f helm/pawhelp/values-prod.yaml
                helm lint helm/crm-manager -f helm/crm-manager/values-dev.yaml
                helm lint helm/teamcity
                helm lint helm/monitoring -f helm/monitoring/values-dev.yaml
                helm lint helm/monitoring -f helm/monitoring/values-prod.yaml
            """.trimIndent()
        }
    }
})

object BuildBackendImage : BuildType({
    id("BuildBackendImage")
    name = "backend test build push"
    vcs { root(BackendRepo) }
    triggers { vcs { } }
    steps {
        script {
            name = "test"
            scriptContent = """
                python -m compileall app
                if [ -d tests ]; then pytest -q; fi
            """.trimIndent()
        }
        script {
            name = "build scan push ecr"
            scriptContent = """
                set -euo pipefail
                REPO="%aws.account.id%.dkr.ecr.%aws.region%.amazonaws.com/pawhelp-backend"
                aws ecr get-login-password --region %aws.region% | docker login --username AWS --password-stdin "%aws.account.id%.dkr.ecr.%aws.region%.amazonaws.com"
                docker build -t "${'$'}REPO:%build.vcs.number%" .
                if command -v trivy >/dev/null 2>&1; then trivy image --exit-code 1 --severity HIGH,CRITICAL "${'$'}REPO:%build.vcs.number%"; fi
                docker push "${'$'}REPO:%build.vcs.number%"
            """.trimIndent()
        }
    }
})

object BuildFrontendImage : BuildType({
    id("BuildFrontendImage")
    name = "frontend test build push"
    vcs { root(FrontendRepo) }
    triggers { vcs { } }
    steps {
        script {
            name = "test"
            scriptContent = """
                npm ci
                npm run lint
                npx expo export --platform web --output-dir dist
            """.trimIndent()
        }
        script {
            name = "build scan push ecr"
            scriptContent = """
                set -euo pipefail
                REPO="%aws.account.id%.dkr.ecr.%aws.region%.amazonaws.com/pawhelp-frontend"
                aws ecr get-login-password --region %aws.region% | docker login --username AWS --password-stdin "%aws.account.id%.dkr.ecr.%aws.region%.amazonaws.com"
                docker build -t "${'$'}REPO:%build.vcs.number%" .
                if command -v trivy >/dev/null 2>&1; then trivy image --exit-code 1 --severity HIGH,CRITICAL "${'$'}REPO:%build.vcs.number%"; fi
                docker push "${'$'}REPO:%build.vcs.number%"
            """.trimIndent()
        }
    }
})

object DeployDev : BuildType({
    id("DeployDev")
    name = "deploy dev"
    vcs { root(InfraRepo) }
    dependencies {
        snapshot(BuildBackendImage) {
            onDependencyFailure = FailureAction.FAIL_TO_START
        }
        snapshot(BuildFrontendImage) {
            onDependencyFailure = FailureAction.FAIL_TO_START
        }
    }
    steps {
        script {
            name = "bump image tags"
            scriptContent = """
                set -euo pipefail
                BACKEND_REPO="%aws.account.id%.dkr.ecr.%aws.region%.amazonaws.com/pawhelp-backend"
                FRONTEND_REPO="%aws.account.id%.dkr.ecr.%aws.region%.amazonaws.com/pawhelp-frontend"
                python scripts/bump_image_tag.py --file helm/pawhelp/values-dev.yaml --component backend --repository "${'$'}BACKEND_REPO" --tag %dep.BuildBackendImage.build.vcs.number%
                python scripts/bump_image_tag.py --file helm/pawhelp/values-dev.yaml --component frontend --repository "${'$'}FRONTEND_REPO" --tag %dep.BuildFrontendImage.build.vcs.number%
                git config user.email "teamcity@pawhelp.local"
                git config user.name "TeamCity"
                git add helm/pawhelp/values-dev.yaml
                git commit -m "Bump images" || true
                git push https://%github.token%@github.com/Osavazya/PawHelp-infra.git HEAD:master
            """.trimIndent()
        }
        script {
            name = "argo wait"
            scriptContent = """
                argocd login %argocd.server% --username %argocd.username% --password %argocd.password% --insecure
                argocd app wait pawhelp-dev --sync --health --timeout 600
            """.trimIndent()
        }
    }
})

object RegressionDev : BuildType({
    id("RegressionDev")
    name = "regression dev"
    vcs { root(InfraRepo) }
    dependencies {
        snapshot(DeployDev) {
            onDependencyFailure = FailureAction.FAIL_TO_START
        }
    }
    steps {
        script {
            name = "smoke regression"
            scriptContent = """
                set -euo pipefail
                curl -fkS https://api.dev.pawhelp.localhost/health
                curl -fkS https://dev.pawhelp.localhost/healthz
                curl -fkS https://crm.dev.pawhelp.localhost/
            """.trimIndent()
        }
    }
})
