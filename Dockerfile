FROM jenkins/jenkins:latest
USER root
# disable the setup wizard as we will set up jenkins as code 
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false -Djenkins.model.Jenkins.crumbIssuerProxyCompatibility=true
# tell the jenkins config-as-code plugin where to find the yaml file
ENV CASC_JENKINS_CONFIG /var/lib/jenkins/jcasc.yaml
# copy the list of plugins we want to install
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
# run the install-plugins script to install the plugins
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt
# copy the config-as-code yaml file into the image
COPY jcasc.yaml /var/lib/jenkins/jcasc.yaml

# ENTRYPOINT ["/usr/bin/tini" "--" "/usr/local/bin/jenkins.sh"]