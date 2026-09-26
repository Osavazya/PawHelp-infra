import jetbrains.buildServer.configs.kotlin.BuildType
import jetbrains.buildServer.configs.kotlin.buildSteps.script
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
                helm lint helm/pawhelp -f helm/pawhelp/values-dev.yaml
                helm lint helm/pawhelp -f helm/pawhelp/values-prod.yaml
                helm lint helm/crm-manager -f helm/crm-manager/values-dev.yaml
                helm lint helm/teamcity
                cd helm/monitoring
                helm dependency build
                helm lint . -f values-dev.yaml
                helm lint . -f values-prod.yaml
            """.trimIndent()
        }
    }
})

object BuildBackendImage : BuildType({
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
            name = "build and push"
            scriptContent = """
                echo %ghcr.token% | docker login ghcr.io -u %ghcr.username% --password-stdin
                docker build -t ghcr.io/osavazya/pawhelp-backend:%build.vcs.number% .
                docker push ghcr.io/osavazya/pawhelp-backend:%build.vcs.number%
            """.trimIndent()
        }
    }
})

object BuildFrontendImage : BuildType({
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
            name = "build and push"
            scriptContent = """
                echo %ghcr.token% | docker login ghcr.io -u %ghcr.username% --password-stdin
                docker build -t ghcr.io/osavazya/pawhelp-frontend:%build.vcs.number% .
                docker push ghcr.io/osavazya/pawhelp-frontend:%build.vcs.number%
            """.trimIndent()
        }
    }
})

object DeployDev : BuildType({
    name = "deploy dev"
    vcs { root(InfraRepo) }
    steps {
        script {
            name = "bump image tags"
            scriptContent = """
                python scripts/bump_image_tag.py --file helm/pawhelp/values-dev.yaml --component backend --tag %backend.image.tag%
                python scripts/bump_image_tag.py --file helm/pawhelp/values-dev.yaml --component frontend --tag %frontend.image.tag%
                git config user.email "teamcity@pawhelp.local"
                git config user.name "TeamCity"
                git add helm/pawhelp/values-dev.yaml
                git commit -m "Bump images" || true
                git push https://%github.token%@github.com/Osavazya/PawHelp-infra.git HEAD:master
            """.trimIndent()
        }
        script {
            name = "argo sync"
            scriptContent = """
                argocd login %argocd.server% --username %argocd.username% --password %argocd.password% --insecure
                argocd app sync pawhelp-dev
                argocd app wait pawhelp-dev --health --timeout 600
            """.trimIndent()
        }
    }
})

object RegressionDev : BuildType({
    name = "regression dev"
    vcs { root(InfraRepo) }
    steps {
        script {
            name = "smoke regression"
            scriptContent = """
                curl -fsS http://api.dev.pawhelp.localhost/health
                curl -fsS http://dev.pawhelp.localhost/healthz
                curl -fsS http://crm.dev.pawhelp.localhost/
            """.trimIndent()
        }
    }
})