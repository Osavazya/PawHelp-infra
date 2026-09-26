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
    vcsRoot(InfraProdRepo)
    vcsRoot(BackendRepo)
    vcsRoot(BackendProdRepo)
    vcsRoot(FrontendRepo)
    vcsRoot(FrontendProdRepo)

    buildType(InfraValidate)
    buildType(BuildBackendImage)
    buildType(BuildFrontendImage)
    buildType(DeployDev)
    buildType(RegressionDev)
    buildType(BuildBackendProdImage)
    buildType(BuildFrontendProdImage)
    buildType(DeployProd)
    buildType(RegressionProd)
}

object InfraRepo : GitVcsRoot({
    name = "PawHelp infra"
    url = "https://github.com/Osavazya/PawHelp-infra.git"
    branch = "refs/heads/master"
})

object InfraProdRepo : GitVcsRoot({
    name = "PawHelp infra prod"
    url = "https://github.com/Osavazya/PawHelp-infra.git"
    branch = "refs/heads/prod"
})

object BackendRepo : GitVcsRoot({
    name = "PawHelp backend"
    url = "https://github.com/Osavazya/PawHelp-backend.git"
    branch = "refs/heads/master"
})

object BackendProdRepo : GitVcsRoot({
    name = "PawHelp backend prod"
    url = "https://github.com/Osavazya/PawHelp-backend.git"
    branch = "refs/heads/prod"
})

object FrontendRepo : GitVcsRoot({
    name = "PawHelp frontend"
    url = "https://github.com/Osavazya/PawHelp-frontend.git"
    branch = "refs/heads/master"
})

object FrontendProdRepo : GitVcsRoot({
    name = "PawHelp frontend prod"
    url = "https://github.com/Osavazya/PawHelp-frontend.git"
    branch = "refs/heads/prod"
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
                helm lint helm/platform -f helm/platform/values.yaml -f helm/platform/values-dev.yaml
                helm lint helm/platform -f helm/platform/values.yaml -f helm/platform/values-prod.yaml
                helm lint helm/pawhelp -f helm/pawhelp/values-dev.yaml
                helm lint helm/pawhelp -f helm/pawhelp/values-prod.yaml
                helm lint helm/crm-manager -f helm/crm-manager/values-dev.yaml
                helm lint helm/crm-manager -f helm/crm-manager/values-prod.yaml
                helm lint helm/teamcity
                helm lint helm/monitoring -f helm/monitoring/values-dev.yaml
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
        backendTestStep()
        backendBuildPushStep()
    }
})

object BuildFrontendImage : BuildType({
    id("BuildFrontendImage")
    name = "frontend test build push"
    vcs { root(FrontendRepo) }
    triggers { vcs { } }
    steps {
        frontendTestStep()
        frontendBuildPushStep()
    }
})

object DeployDev : BuildType({
    id("DeployDev")
    name = "deploy dev"
    vcs { root(InfraRepo) }
    dependencies {
        snapshot(BuildBackendImage) { onDependencyFailure = FailureAction.FAIL_TO_START }
        snapshot(BuildFrontendImage) { onDependencyFailure = FailureAction.FAIL_TO_START }
    }
    steps {
        gitOpsBumpStep("helm/pawhelp/values-dev.yaml", "master", "BuildBackendImage", "BuildFrontendImage")
        argoWaitStep("pawhelp-dev")
    }
})

object RegressionDev : BuildType({
    id("RegressionDev")
    name = "regression dev"
    vcs { root(InfraRepo) }
    dependencies {
        snapshot(DeployDev) { onDependencyFailure = FailureAction.FAIL_TO_START }
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

object BuildBackendProdImage : BuildType({
    id("BuildBackendProdImage")
    name = "backend prod test build push"
    vcs { root(BackendProdRepo) }
    steps {
        backendTestStep()
        backendBuildPushStep()
    }
})

object BuildFrontendProdImage : BuildType({
    id("BuildFrontendProdImage")
    name = "frontend prod test build push"
    vcs { root(FrontendProdRepo) }
    steps {
        frontendTestStep()
        frontendBuildPushStep()
    }
})

object DeployProd : BuildType({
    id("DeployProd")
    name = "deploy prod"
    vcs { root(InfraProdRepo) }
    dependencies {
        snapshot(BuildBackendProdImage) { onDependencyFailure = FailureAction.FAIL_TO_START }
        snapshot(BuildFrontendProdImage) { onDependencyFailure = FailureAction.FAIL_TO_START }
    }
    steps {
        gitOpsBumpStep("helm/pawhelp/values-prod.yaml", "prod", "BuildBackendProdImage", "BuildFrontendProdImage")
        argoWaitStep("pawhelp-prod")
    }
})

object RegressionProd : BuildType({
    id("RegressionProd")
    name = "regression prod"
    vcs { root(InfraProdRepo) }
    dependencies {
        snapshot(DeployProd) { onDependencyFailure = FailureAction.FAIL_TO_START }
    }
    steps {
        script {
            name = "smoke regression"
            scriptContent = """
                set -euo pipefail
                curl -fkS https://api.pawhelp.localhost/health
                curl -fkS https://pawhelp.localhost/healthz
                curl -fkS https://crm.pawhelp.localhost/
            """.trimIndent()
        }
    }
})

fun jetbrains.buildServer.configs.kotlin.BuildSteps.backendTestStep() = script {
    name = "test"
    scriptContent = """
        python -m compileall app
        if [ -d tests ]; then pytest -q; fi
    """.trimIndent()
}

fun jetbrains.buildServer.configs.kotlin.BuildSteps.backendBuildPushStep() = script {
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

fun jetbrains.buildServer.configs.kotlin.BuildSteps.frontendTestStep() = script {
    name = "test"
    scriptContent = """
        npm ci
        npm run lint
        npx expo export --platform web --output-dir dist
    """.trimIndent()
}

fun jetbrains.buildServer.configs.kotlin.BuildSteps.frontendBuildPushStep() = script {
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

fun jetbrains.buildServer.configs.kotlin.BuildSteps.gitOpsBumpStep(valuesFile: String, branch: String, backendBuildId: String, frontendBuildId: String) = script {
    name = "bump image tags"
    scriptContent = """
        set -euo pipefail
        BACKEND_REPO="%aws.account.id%.dkr.ecr.%aws.region%.amazonaws.com/pawhelp-backend"
        FRONTEND_REPO="%aws.account.id%.dkr.ecr.%aws.region%.amazonaws.com/pawhelp-frontend"
        python scripts/bump_image_tag.py --file $valuesFile --component backend --repository "${'$'}BACKEND_REPO" --tag %dep.$backendBuildId.build.vcs.number%
        python scripts/bump_image_tag.py --file $valuesFile --component frontend --repository "${'$'}FRONTEND_REPO" --tag %dep.$frontendBuildId.build.vcs.number%
        git config user.email "teamcity@pawhelp.local"
        git config user.name "TeamCity"
        git add $valuesFile
        git commit -m "Bump images" || true
        git push https://x-access-token:%github.token%@github.com/Osavazya/PawHelp-infra.git HEAD:$branch
    """.trimIndent()
}

fun jetbrains.buildServer.configs.kotlin.BuildSteps.argoWaitStep(appName: String) = script {
    name = "argo wait"
    scriptContent = """
        argocd login %argocd.server% --username %argocd.username% --password %argocd.password% --insecure
        argocd app wait $appName --sync --health --timeout 600
    """.trimIndent()
}