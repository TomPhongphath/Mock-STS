import hudson.security.AuthorizationStrategy
import hudson.security.SecurityRealm
import jenkins.model.Jenkins

def jenkins = Jenkins.instance
jenkins.setSecurityRealm(SecurityRealm.NO_AUTHENTICATION)
jenkins.setAuthorizationStrategy(new AuthorizationStrategy.Unsecured())
jenkins.save()

println("[disable-security-for-mock] Jenkins security disabled for local mock environment.")
