import jetbrains.buildServer.configs.kotlin.BuildType
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.project
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
    vcs {
        root(InfraRepo)
    }
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
                cd helm/pawhelp
                helm lint . -f values-dev.yaml
                helm lint . -f values-prod.yaml
                cd ../monitoring
                helm dependency build
                helm lint . -f values-dev.yaml
                helm lint . -f values-prod.yaml
            """.trimIndent()
        }
    }
})

object BuildBackendImage : BuildType({
    name = "build backend image"
    vcs {
        root(BackendRepo)
    }
    steps {
        script {
            name = "docker build push"
            scriptContent = """
                docker build -t ghcr.io/osavazya/pawhelp-backend:%build.vcs.number% .
                docker push ghcr.io/osavazya/pawhelp-backend:%build.vcs.number%
            """.trimIndent()
        }
    }
})

object BuildFrontendImage : BuildType({
    name = "build frontend image"
    vcs {
        root(FrontendRepo)
    }
    steps {
        script {
            name = "docker build push"
            scriptContent = """
                docker build -t ghcr.io/osavazya/pawhelp-frontend:%build.vcs.number% .
                docker push ghcr.io/osavazya/pawhelp-frontend:%build.vcs.number%
            """.trimIndent()
        }
    }
})