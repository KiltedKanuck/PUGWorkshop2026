import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.XmlReport
import jetbrains.buildServer.configs.kotlin.buildFeatures.perfmon
import jetbrains.buildServer.configs.kotlin.buildFeatures.xmlReport
import jetbrains.buildServer.configs.kotlin.buildSteps.gradle
import jetbrains.buildServer.configs.kotlin.buildSteps.script
import jetbrains.buildServer.configs.kotlin.failureConditions.BuildFailureOnMetric
import jetbrains.buildServer.configs.kotlin.failureConditions.BuildFailureOnText
import jetbrains.buildServer.configs.kotlin.failureConditions.failOnMetricChange
import jetbrains.buildServer.configs.kotlin.failureConditions.failOnText
import jetbrains.buildServer.configs.kotlin.triggers.VcsTrigger
import jetbrains.buildServer.configs.kotlin.triggers.finishBuildTrigger
import jetbrains.buildServer.configs.kotlin.triggers.vcs

/*
The settings script is an entry point for defining a TeamCity
project hierarchy. The script should contain a single call to the
project() function with a Project instance or an init function as
an argument.

VcsRoots, BuildTypes, Templates, and subprojects can be
registered inside the project using the vcsRoot(), buildType(),
template(), and subProject() methods respectively.

To debug settings scripts in command-line, run the

    mvnDebug org.jetbrains.teamcity:teamcity-configs-maven-plugin:generate

command and attach your debugger to the port 8000.

To debug in IntelliJ Idea, open the 'Maven Projects' tool window (View
-> Tool Windows -> Maven Projects), find the generate task node
(Plugins -> teamcity-configs -> teamcity-configs:generate), the
'Debug' option is available in the context menu for the task.
*/

version = "2025.11"

project {
    description = """
        Build and upload artifacts for OpenEdge Load Suite (OELS) to be used for high-load testing of customer scenarios.
        THIS IS A CRITICAL TEST SUITE FOR MEASURING PASOE/DATABASE PERFORMANCE!
        Please contact the A-Team for more information.
    """.trimIndent()

    template(LoadSuiteBuildLinux)
    template(LoadSuiteUploadLinux)

    params {
        param("env.app_api_version", "1.0.0")
        param("OE_MAVEN_ORG", "com/progress/openedge")
        param("ARTIFACTORY_MAVEN_REPO", "oe-maven-develop-bedford")
        param("GIT_BRANCH_FILTER", "+:*")
        param("env.packageType", "tty")
        param("JAVA_HOME", "%env.JAVA_HOME%")
        param("TC_CHK_PLAT", "%TC_CHK_LIN%")
        param("env.dlcType", "linuxx86_64")
        param("MACHID", "%env.dlcType%")
        param("env.JAVA_HOME", "%linuxx86_64_JAVA_HOME%")
        param("linuxx86_64_JAVA_HOME", "/tools/linuxx86_64/java/jdk-17.0.3+7")
        param("GIT_BRANCH_SPEC", """
            +:refs/heads/main
            +:refs/heads/develop-*
        """.trimIndent())
        param("TOOLNAME", "OpenEdge.LoadSuite")
        param("gitbranch", "main")
        param("CURL_EXEC", "curl")
        param("TC_CHK_LIN", "/shared/teamcity_scripts/tc_chk_errors/scan_build_log")
        param("MAVEN_UPLOAD_BUILDNAME", "%TOOLNAME%_maven_%env.app_api_version%")
        param("system.build_target_oe_version", "")
        param("COMPONENT", "oels")
        param("GIT_DEFAULT_BRANCH", "refs/heads/main")
    }
    subProjectsOrder = arrayListOf(RelativeId("Oe1310"), RelativeId("Oe128x"), RelativeId("Containerization"))

    subProject(Containerization)
    subProject(Oe1310)
    subProject(Oe128x)
}

object LoadSuiteBuildLinux : Template({
    name = "LoadSuite_Build_Linux"
    description = "Build Process for Linux"

    allowExternalStatus = true
    artifactRules = """
        build/dist => build/dist
        teamcitybuild.log=>.
    """.trimIndent()
    maxRunningBuilds = 1
    publishArtifacts = PublishMode.SUCCESSFUL

    vcs {
        root(RelativeId("OpenEdgeLoadSuite"))

        cleanCheckout = true
        branchFilter = "%GIT_BRANCH_FILTER%"
    }

    steps {
        gradle {
            name = "Build Project Artifacts"
            id = "OEMP_Build"
            gradleParams = "--info --refresh-dependencies"
            jdkHome = "%env.JAVA_HOME%"
            param("org.jfrog.artifactory.selectedDeployableServer.defaultModuleVersionConfiguration", "GLOBAL")
        }
        script {
            name = "Download Build log"
            id = "Download_Build_log"
            scriptContent = """
                echo "Downloading buildlog [%teamcity.build.id%]"
                echo "----------"
                %CURL_EXEC% -k %TC_BUILD_LOG% -o teamcitybuild.log
                echo "----------"
            """.trimIndent()
            param("org.jfrog.artifactory.selectedDeployableServer.downloadSpecSource", "Job configuration")
            param("org.jfrog.artifactory.selectedDeployableServer.useSpecs", "false")
            param("org.jfrog.artifactory.selectedDeployableServer.uploadSpecSource", "Job configuration")
        }
        script {
            name = "Scan Build log for errors"
            id = "Scan_Build_log_for_errors"
            scriptContent = "%TC_CHK_PLAT% teamcitybuild.log"
            param("org.jfrog.artifactory.selectedDeployableServer.downloadSpecSource", "Job configuration")
            param("org.jfrog.artifactory.selectedDeployableServer.useSpecs", "false")
            param("org.jfrog.artifactory.selectedDeployableServer.uploadSpecSource", "Job configuration")
        }
    }

    triggers {
        vcs {
            id = "TRIGGER_929"
            quietPeriodMode = VcsTrigger.QuietPeriodMode.USE_DEFAULT
            branchFilter = "%GIT_BRANCH_FILTER%"
        }
    }

    failureConditions {
        errorMessage = true
        failOnMetricChange {
            id = "BUILD_EXT_956"
            metric = BuildFailureOnMetric.MetricType.TEST_FAILED_COUNT
            threshold = 0
            units = BuildFailureOnMetric.MetricUnit.DEFAULT_UNIT
            comparison = BuildFailureOnMetric.MetricComparison.MORE
            compareTo = value()
            stopBuildOnFailure = true
        }
        failOnText {
            id = "BUILD_EXT_957"
            conditionType = BuildFailureOnText.ConditionType.CONTAINS
            pattern = "error signing"
            failureMessage = "Build Failed. Signing error."
            reverse = false
        }
        failOnText {
            id = "BUILD_EXT_958"
            conditionType = BuildFailureOnText.ConditionType.CONTAINS
            pattern = "unable to sign jar"
            failureMessage = "Build Failed. Signing error."
            reverse = false
        }
        failOnText {
            id = "BUILD_EXT_959"
            conditionType = BuildFailureOnText.ConditionType.CONTAINS
            pattern = "not verified"
            failureMessage = "Build Failed. Check build log for details."
            reverse = false
        }
    }

    features {
        perfmon {
            id = "perfmon"
        }
        xmlReport {
            id = "BUILD_EXT_960"
            reportType = XmlReport.XmlReportType.JUNIT
            rules = "build/tests/**/results.xml"
        }
    }
})

object LoadSuiteUploadLinux : Template({
    name = "LoadSuite_Upload_Linux"
    description = "Upload Template for Artifactory"

    allowExternalStatus = true
    maxRunningBuilds = 1
    publishArtifacts = PublishMode.SUCCESSFUL

    vcs {
        cleanCheckout = true
        branchFilter = "%GIT_BRANCH_FILTER%"
    }

    steps {
        script {
            name = "Upload to Artifactory"
            id = "Upload"
            scriptContent = """echo "Upload to Artifactory""""
            param("org.jfrog.artifactory.selectedDeployableServer.publishBuildInfo", "true")
            param("org.jfrog.artifactory.selectedDeployableServer.customBuildName", "%MAVEN_UPLOAD_BUILDNAME%")
            param("org.jfrog.artifactory.selectedDeployableServer.useSpecs", "true")
            param("org.jfrog.artifactory.selectedDeployableServer.urlId", "2")
            param("org.jfrog.artifactory.selectedDeployableServer.envVarsExcludePatterns", "*password*,*secret*")
            param("org.jfrog.artifactory.selectedDeployableServer.buildRetention", "true")
            param("org.jfrog.artifactory.selectedDeployableServer.uploadSpec", """
                {
                    "files": [
                        {
                            "pattern": "build/dist/%TOOLNAME%.apl",
                            "target": "%ARTIFACTORY_MAVEN_REPO%/%OE_MAVEN_ORG%/%COMPONENT%/%env.app_api_version%/%TOOLNAME%-%system.build_target_oe_version%-%env.dlcType%.apl"
                        },
                        {
                            "pattern": "build/dist/%TOOLNAME%.pl",
                            "target": "%ARTIFACTORY_MAVEN_REPO%/%OE_MAVEN_ORG%/%COMPONENT%/%env.app_api_version%/%TOOLNAME%-%system.build_target_oe_version%-%env.dlcType%.pl"
                        },
                        {
                            "pattern": "build/dist/%TOOLNAME%.zip",
                            "target": "%ARTIFACTORY_MAVEN_REPO%/%OE_MAVEN_ORG%/%COMPONENT%/%env.app_api_version%/%TOOLNAME%-%system.build_target_oe_version%-%env.dlcType%.zip"
                        },
                        {
                            "pattern": "build/dist/%TOOLNAME%-listings.zip",
                            "target": "%ARTIFACTORY_MAVEN_REPO%/%OE_MAVEN_ORG%/%COMPONENT%/%env.app_api_version%/%TOOLNAME%-%system.build_target_oe_version%-listings.zip"
                        },
                        {
                            "pattern": "build/dist/%TOOLNAME%-preprocess.zip",
                            "target": "%ARTIFACTORY_MAVEN_REPO%/%OE_MAVEN_ORG%/%COMPONENT%/%env.app_api_version%/%TOOLNAME%-%system.build_target_oe_version%-preprocess.zip"
                        },
                        {
                            "pattern": "build/dist/installer.zip",
                            "target": "%ARTIFACTORY_MAVEN_REPO%/%OE_MAVEN_ORG%/%COMPONENT%/%env.app_api_version%/%COMPONENT%-%system.build_target_oe_version%.zip"
                        },
                        {
                            "pattern": "build/dist/k6-tests.zip",
                            "target": "%ARTIFACTORY_MAVEN_REPO%/%OE_MAVEN_ORG%/%COMPONENT%/%env.app_api_version%/%COMPONENT%-%env.app_api_version%-k6-tests.zip"
                        },
                        {
                            "pattern": "build/dist/docker-support.zip",
                            "target": "%ARTIFACTORY_MAVEN_REPO%/%OE_MAVEN_ORG%/%COMPONENT%/%env.app_api_version%/%COMPONENT%-%env.app_api_version%-docker-support.zip"
                        },
                        {
                            "pattern": "build/dist/TestMemory.oemp",
                            "target": "%ARTIFACTORY_MAVEN_REPO%/%OE_MAVEN_ORG%/%COMPONENT%/%env.app_api_version%/testing-%system.build_target_oe_version%-memory.oemp"
                        },
                        {
                            "pattern": "build/dist/TestPerformance.prof",
                            "target": "%ARTIFACTORY_MAVEN_REPO%/%OE_MAVEN_ORG%/%COMPONENT%/%env.app_api_version%/testing-%system.build_target_oe_version%-performance.prof"
                        },
                        {
                            "pattern": "teamcitybuild.log",
                            "target": "%ARTIFACTORY_MAVEN_REPO%/%OE_MAVEN_ORG%/%COMPONENT%/%env.app_api_version%/%COMPONENT%-%system.build_target_oe_version%-teamcity.log"
                        }
                    ]
                }
            """.trimIndent())
            param("org.jfrog.artifactory.selectedDeployableServer.buildRetentionDeleteArtifacts", "true")
            param("org.jfrog.artifactory.selectedDeployableServer.downloadSpecSource", "Job configuration")
            param("org.jfrog.artifactory.selectedDeployableServer.uploadSpecSource", "Job configuration")
            param("org.jfrog.artifactory.selectedDeployableServer.targetRepo", "common-docker-play-bedford")
        }
    }

    failureConditions {
        errorMessage = true
    }

    requirements {
        startsWith("system.agent.name", "tclinuxbld", "RQ_1049")
    }
})


object Containerization : Project({
    name = "Containerization"
    description = "Create containers for project components"

    buildType(Containerization_DockerContainerForK6Client)
    buildTypesOrder = arrayListOf(Containerization_DockerContainerForK6Client)
})

object Containerization_DockerContainerForK6Client : BuildType({
    name = "Docker Container for k6 Client"
    description = "Build a client Docker container image for k6 tests against the OpenEdge Load Suite"

    allowExternalStatus = true
    artifactRules = """
        build/dist => build/dist
        teamcitybuild.log=>.
    """.trimIndent()
    maxRunningBuilds = 1
    publishArtifacts = PublishMode.SUCCESSFUL

    params {
        param("system.docker_appname", "k6")
        param("system.docker_group", "oels")
    }

    vcs {
        root(RelativeId("OpenEdgeLoadSuite"))

        cleanCheckout = true
        branchFilter = "%GIT_BRANCH_FILTER%"
    }

    steps {
        script {
            name = "Report Docker Environment"
            id = "Clean_Docker_Environment"
            scriptContent = """
                echo "=== Containers ==="
                docker ps -a
                
                echo "=== Images ==="
                docker images
                
                echo "=== Dangling ==="
                for image in ${'$'}(docker images -q | sort -u); do
                  labels=${'$'}(docker inspect --format '{{.Config.Labels}}' "${'$'}image")
                  if [[ "${'$'}labels" == *"%system.docker_group%:%system.docker_appname%"* ]]; then
                    if [[ "${'$'}labels" == *"stage:builder"* ]]; then
                      id_full=${'$'}(docker inspect --format '{{.Id}}' "${'$'}image")
                      id_short=${'$'}{id_full:7:12}
                      tags=${'$'}(docker inspect --format '{{.RepoTags}}' "${'$'}image")
                
                      echo "Image ID: ${'$'}id_short"
                      echo "Tags:     ${'$'}tags"
                      echo "Labels:   ${'$'}labels"
                      echo
                    fi
                  fi
                done
                
                echo "=== Cleanup ==="
                for image in ${'$'}(docker images -q | sort -u); do
                  labels=${'$'}(docker inspect --format '{{.Config.Labels}}' "${'$'}image")
                  if [[ "${'$'}labels" == *"%system.docker_group%:%system.docker_appname%"* ]]; then
                    if [[ "${'$'}labels" == *"stage:builder"* ]]; then
                      docker rmi -f "${'$'}image"
                    fi
                  fi
                done
            """.trimIndent()
            param("org.jfrog.artifactory.selectedDeployableServer.downloadSpecSource", "Job configuration")
            param("org.jfrog.artifactory.selectedDeployableServer.useSpecs", "false")
            param("org.jfrog.artifactory.selectedDeployableServer.uploadSpecSource", "Job configuration")
        }
        gradle {
            name = "Create Base and Product Containers"
            id = "Create_Container"
            tasks = "containerize"
            gradleParams = "--info  --refresh-dependencies"
            jdkHome = "%linuxx86_64_JAVA_HOME%"
            param("org.jfrog.artifactory.selectedDeployableServer.defaultModuleVersionConfiguration", "GLOBAL")
        }
        script {
            name = "Upload Container"
            id = "Upload_Container"
            scriptContent = """echo "Uploading Container""""
            param("org.jfrog.artifactory.selectedDeployableServer.publishBuildInfo", "true")
            param("org.jfrog.artifactory.selectedDeployableServer.customBuildName", "%MAVEN_UPLOAD_BUILDNAME%")
            param("org.jfrog.artifactory.selectedDeployableServer.useSpecs", "true")
            param("org.jfrog.artifactory.selectedDeployableServer.urlId", "2")
            param("org.jfrog.artifactory.selectedDeployableServer.envVarsExcludePatterns", "*password*,*secret*")
            param("org.jfrog.artifactory.selectedDeployableServer.uploadSpec", """
                {
                    "files": [
                        {
                            "pattern": "build/dist/k6client-docker-image.zip",
                            "target": "%ARTIFACTORY_MAVEN_REPO%/%OE_MAVEN_ORG%/%COMPONENT%/%env.app_api_version%/%COMPONENT%-%env.app_api_version%-k6-client-docker.zip"
                        }
                    ]
                }
            """.trimIndent())
            param("org.jfrog.artifactory.selectedDeployableServer.downloadSpecSource", "Job configuration")
            param("org.jfrog.artifactory.selectedDeployableServer.uploadSpecSource", "Job configuration")
            param("org.jfrog.artifactory.selectedDeployableServer.targetRepo", "common-docker-play-bedford")
        }
    }

    triggers {
        finishBuildTrigger {
            buildType = "${Oe1310_UploadToArtifactory.id}"
            successfulOnly = true
            branchFilter = "%GIT_BRANCH_FILTER%"
        }
    }

    failureConditions {
        executionTimeoutMin = 30
        errorMessage = true
    }

    dependencies {
        snapshot(Oe1310_UploadToArtifactory) {
            onDependencyFailure = FailureAction.CANCEL
            onDependencyCancel = FailureAction.CANCEL
        }
    }

    requirements {
        contains("teamcity.agent.hostname", "oedockerce")
    }
})


object Oe128x : Project({
    name = "OE 12.8.x"
    description = "Pipeline for building against OE 12.8 LTS"

    buildType(Oe128x_Build)
    buildType(Oe128x_UploadToArtifactory)

    params {
        param("system.build_target_oe_version", "12.8.11")
        param("system.build_stage", "staging")
        param("env.oe.major.minor.sp.version", "12.8.0")
    }
    buildTypesOrder = arrayListOf(Oe128x_Build, Oe128x_UploadToArtifactory)
})

object Oe128x_Build : BuildType({
    templates(LoadSuiteBuildLinux)
    name = "Build"

    params {
        password("env.BD_TOKEN", "zxx83eb094e2c4421f1570a9442022f2cbbc8e14d11d58a6c36215ef96a39b3ba9e49b69eca0d7b51a78fcbe7be933703e1a332a9d41e75c715067319e6d433f7ea462367da1a243bb57fd55b983bb2b769bc7e91d616a30768e6b19f946030e3a73fff6d260b1dc23a", display = ParameterDisplay.HIDDEN)
        param("env.TERM", "xterm")
        password("env.BRIDGE_POLARIS_ACCESSTOKEN", "zxx1fe30fca2894517d0d1f01a22d61ec62c44a87a7bdef35d67ec38b4a665d447c9cd2c74c1227fd4cbb5cb99153bd1a80c68baf47fad1abea3937f3b976c21b5ed83b3eb775e899597b61c0682d97fd21", display = ParameterDisplay.HIDDEN)
        param("env.SB", "%teamcity.build.checkoutDir%/synopsys-bridge")
    }

    requirements {
        startsWith("teamcity.agent.name", "tclinuxbld", "RQ_1048")
    }
    
    disableSettings("BUILD_EXT_960", "Generate_p7b", "Sign_APL_files")
})

object Oe128x_UploadToArtifactory : BuildType({
    templates(LoadSuiteUploadLinux)
    name = "Upload_to_Artifactory"

    triggers {
        finishBuildTrigger {
            id = "TRIGGER_914"
            buildType = "${Oe128x_Build.id}"
            successfulOnly = true
        }
    }

    dependencies {
        dependency(Oe128x_Build) {
            snapshot {
                onDependencyFailure = FailureAction.CANCEL
                onDependencyCancel = FailureAction.CANCEL
            }

            artifacts {
                id = "ARTIFACT_DEPENDENCY_406"
                artifactRules = """
                    build/dist => build/dist
                    teamcitybuild.log=>.
                """.trimIndent()
            }
        }
    }
})


object Oe1310 : Project({
    name = "OE 13.1.0"
    description = "Pipeline for building against OE 13.1.0"

    buildType(Oe1310_Build)
    buildType(Oe1310_UploadToArtifactory)

    params {
        param("system.build_target_oe_version", "13.1.0")
        param("system.build_stage", "develop")
        param("env.oe.major.minor.sp.version", "13.1.0")
    }
    buildTypesOrder = arrayListOf(Oe1310_Build, Oe1310_UploadToArtifactory)
})

object Oe1310_Build : BuildType({
    templates(LoadSuiteBuildLinux)
    name = "Build"

    params {
        param("env.TERM", "xterm")
        password("env.BD_TOKEN", "zxx83eb094e2c4421f1570a9442022f2cbbc8e14d11d58a6c36215ef96a39b3ba9e49b69eca0d7b51a78fcbe7be933703e1a332a9d41e75c715067319e6d433f7ea462367da1a243bb57fd55b983bb2b769bc7e91d616a30768e6b19f946030e3a73fff6d260b1dc23a", display = ParameterDisplay.HIDDEN)
        password("env.BRIDGE_POLARIS_ACCESSTOKEN", "zxx1fe30fca2894517d0d1f01a22d61ec62c44a87a7bdef35d67ec38b4a665d447c9cd2c74c1227fd4cbb5cb99153bd1a80c68baf47fad1abea3937f3b976c21b5ed83b3eb775e899597b61c0682d97fd21", display = ParameterDisplay.HIDDEN)
        param("env.SB", "%teamcity.build.checkoutDir%/synopsys-bridge")
    }

    requirements {
        startsWith("teamcity.agent.name", "tclinuxbld", "RQ_1048")
    }
    
    disableSettings("BUILD_EXT_960", "Generate_p7b", "Sign_APL_files")
})

object Oe1310_UploadToArtifactory : BuildType({
    templates(LoadSuiteUploadLinux)
    name = "Upload_to_Artifactory"

    triggers {
        finishBuildTrigger {
            id = "TRIGGER_914"
            buildType = "${Oe1310_Build.id}"
            successfulOnly = true
        }
    }

    dependencies {
        dependency(Oe1310_Build) {
            snapshot {
                onDependencyFailure = FailureAction.CANCEL
                onDependencyCancel = FailureAction.CANCEL
            }

            artifacts {
                id = "ARTIFACT_DEPENDENCY_406"
                artifactRules = """
                    build/dist => build/dist
                    teamcitybuild.log=>.
                """.trimIndent()
            }
        }
    }
})
