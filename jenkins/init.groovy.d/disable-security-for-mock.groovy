import jenkins.model.Jenkins
import hudson.security.SecurityRealm
import hudson.security.AuthorizationStrategy
import hudson.security.csrf.DefaultCrumbIssuer

def jenkins = Jenkins.instance

jenkins.setSecurityRealm(SecurityRealm.NO_AUTHENTICATION)
jenkins.setAuthorizationStrategy(new AuthorizationStrategy.Unsecured())

jenkins.setCrumbIssuer(null)
jenkins.save()

println("[disable-security-for-mock] Security disabled, CSRF disabled.")
