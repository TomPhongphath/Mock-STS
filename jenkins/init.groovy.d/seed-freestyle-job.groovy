import jenkins.model.Jenkins
import java.io.ByteArrayInputStream
import javax.xml.transform.stream.StreamSource

def jenkins = Jenkins.instance

def upsertFromXml = { String jobName, String xml ->
    def existing = jenkins.getItem(jobName)
    def bytes = xml.getBytes("UTF-8")
    if (existing == null) {
        new ByteArrayInputStream(bytes).withStream { stream ->
            jenkins.createProjectFromXML(jobName, stream)
        }
        println("[seed-freestyle-job] Created job: ${jobName}")
    } else {
        new ByteArrayInputStream(bytes).withStream { stream ->
            existing.updateByXml(new StreamSource(stream))
        }
        existing.save()
        println("[seed-freestyle-job] Updated job: ${jobName}")
    }
}

def deleteJobIfExists = { String jobName ->
    def job = jenkins.getItem(jobName)
    if (job != null) {
        job.delete()
        println("[seed-freestyle-job] Removed legacy job: ${jobName}")
    }
}

// Remove legacy single orchestrator job to keep Jenkins as per-service layout
deleteJobIfExists("Mock-STS-Freestyle-CI-CD")

// Seed per-service freestyle jobs (10 services)
def serviceTemplateFile = new File("/opt/jenkins-job-templates/_templates/service-job-config.xml")
if (!serviceTemplateFile.exists()) {
    println("[seed-freestyle-job] Service template not found: ${serviceTemplateFile.absolutePath}")
    jenkins.save()
    return
}

def serviceTemplate = serviceTemplateFile.getText("UTF-8")
def services = [
    [repo: "STS-ADM", owner: "TomPhongphath", master: "sts-adm-master", uat: "sts-adm-uat", hasCompose: true],
    [repo: "STS-ALERT", owner: "TomPhongphath", master: "sts-alert-master", uat: "sts-alert-uat", hasCompose: true],
    [repo: "STS-Common", owner: "TomPhongphath", master: "", uat: "", hasCompose: false],
    [repo: "STS-DASHBOARD", owner: "TomPhongphath", master: "sts-dashboard-master", uat: "sts-dashboard-uat", hasCompose: true],
    [repo: "STS-INSTALL", owner: "TomPhongphath", master: "sts-install-master", uat: "sts-install-uat", hasCompose: true],
    [repo: "STS-INVENTORY-CONTROL", owner: "TomPhongphath", master: "", uat: "", hasCompose: false],
    [repo: "STS-MASTER", owner: "TomPhongphath", master: "sts-master-master", uat: "sts-master-uat", hasCompose: true],
    [repo: "STS-NOC", owner: "TomPhongphath", master: "sts-noc-master", uat: "sts-noc-uat", hasCompose: true],
    [repo: "SCS-TELEPORT", owner: "TomPhongphath", master: "sts-teleport-master", uat: "sts-teleport-uat", hasCompose: true],
    [repo: "sts-portal", owner: "TomPhongphath", master: "sts-portal-master", uat: "sts-portal-uat", hasCompose: true],
]

services.each { service ->
    // Remove previous non-split job naming
    deleteJobIfExists("${service.repo}-Freestyle-CI-CD")

    [
        [env: "MASTER", target: service.master as String, branch: "MASTER-MOCK"],
        [env: "UAT", target: service.uat as String, branch: "UAT-MOCK"],
    ].each { spec ->
        // Remove old suffixed naming for split jobs
        deleteJobIfExists("${service.repo}-${spec.env}-Freestyle-CI-CD")

        def hasComposeForEnv = (service.hasCompose as boolean) && (spec.target?.trim())
        def jobName = "${service.repo}-${spec.env}"
        def description = "Freestyle CI/CD for ${service.repo} (${spec.env}, branch ${spec.branch}). ACTION=auto|sync|ci|start|restart|stop|status|logs"

        def xml = serviceTemplate
            .replace("__JOB_DESCRIPTION__", description)
            .replace("__REPO_DIR__", service.repo as String)
            .replace("__REPO_OWNER__", service.owner as String)
            .replace("__TARGET_ENV__", spec.env as String)
            .replace("__TARGET_BRANCH__", spec.branch as String)
            .replace("__TARGET_SERVICE__", spec.target ?: "")
            .replace("__HAS_COMPOSE_SERVICE__", hasComposeForEnv.toString())

        upsertFromXml(jobName, xml)
    }
}

jenkins.save()
