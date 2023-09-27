
# Jenkins (Setup Jenkins Master on K8s)

https://www.jenkins.io/doc/
https://www.jenkins.io/doc/book/installing/kubernetes/

## What is Jenkins?
----------

Jenkins is an open-source automation server that is widely used for automating various tasks related to building, testing, and deploying software applications. As of August 2023 it remains to be a popular tool in the field of continuous integration and continuous delivery (CI/CD), which are essential practices in modern software development.

Historically, Jenkins master and agents behaved as if they all together form a single distributed process. This means an agent can ask a master to do just about anything within the confinement of the operating system, such as accessing files on the master or trigger other jobs on Jenkins.

This has increasingly become problematic, as larger enterprise deployments have developed more sophisticated trust separation model, where the administrators of a master might take agents owned by other teams. In such an environment, agents are less trusted than the master.

In later version Jenkins added a subsystem to put a wall between a master and an agent to safely allow less trusted agents to be connected to a master.

### Advantages of Jenkins:
- It is an open-sourse tool with great community support
- It easy to install
- It has 1000+plugins to ease your work. If plugin does not exist, you can code it and share it with the  community.
- It is free of cost
- It is build with Java and hence, it is portable to all the major platforms.    

Visit Jenkins Documentaion for more information about Jenkins:  
[Jenkins User Documentation](https://www.jenkins.io/doc/)


### Jenkins Controller Key Functions 

-----


Job Scheduling: Orchestrates and schedules Jenkins jobs and pipelines to run at specific times or in response to certain events.

User Interface: Provides a web-based graphical user interface (UI) for configuring and monitoring jobs, pipelines, and the overall Jenkins environment.

Job Configuration: Allows users to define job settings, including source code repositories, build triggers, build steps, post-build actions, and more.

Plugin Management: Manages plugins that extend Jenkins' functionality. Users can install and configure plugins to add new features and integrations.

Security: Handles user authentication, authorization, and access control to ensure that only authorized users have the right permissions to perform specific actions in Jenkins.

Agent Management: Coordinates the provisioning and utilization of build agents (also known as nodes or slaves) to distribute and execute build and test workloads.

Build Execution: Distributes build and test workloads to the configured build agents, ensuring that jobs are executed efficiently and in parallel.

Artifact Management: Stores and serves build artifacts and results, making it easy to access and distribute the outputs of Jenkins builds.

Build Triggers: Allows for the initiation of jobs manually by users or automatically in response to events such as code commits, pull requests, or other triggers.

Integration: Integrates with external tools and services through plugins, enabling Jenkins to connect with version control systems, issue trackers, deployment platforms, and other DevOps and CI/CD tools.

These components collectively enable Jenkins to automate the build, test, and deployment processes, making it a powerful tool for continuous integration and continuous delivery in software development.



### Kubernetes Resources

1. Create namaspace "jenkins-master" (you can deploy Jenkins at any namespace, but it is recommended that you create a dedicated namespace)

2. Create Jenkins Statefulset that will assume role as controller node and named as jenkins, open 2 ports
   - port 8080 : will be used for acccessing Jenkins API
   - port 50000 : will be used by Jenkins agent node (jnlp) and controller node to communicate with each other

3. The Statefulset includes configuration of the Service resource, named "jenkins-svc" in the "jenkins-master" namespace, enables vital network communication for Jenkins, with ports 8080 (HTTP) and 50000 (agent) for web access and job execution. It selects pods labeled "app: jenkins" to ensure proper routing.

4. The StatefulSet includes environment variables designed to access Kubernetes secrets, which  are subsequently utilized to retrieve secrets from AWS Secret Manager via the CSI driver.

5. Volume Details: There is a defined volume named "secret-store" that is mounted inside the containers at the path "/mnt/secret-store." This volume is configured to be read-only, meaning that the data within it cannot be modified by the container.

6. Volume Attributes: Within this volume configuration, we specify additional attributes related to the volume. Specifically, we set the "secretProviderClass" attribute to "jenkins-secrets." This indicates that the volume is associated with a SecretProviderClass named "jenkins-secrets."

(This configuration is essential for securely managing and retrieving secrets required by the Jenkins application deployed within Kubernetes. The secrets are stored and managed using the CSI (Container Storage Interface) driver with the ability to access the secrets stored in AWS Secret Manager.)
Please note: The volume details and attributes were configured at a later stage upon installation of CSI driver and configuring SecretProvideClass.

7. Add Kubernetes Service Account, ClusterRole and ClusterRoleBinding for Jenkins
   - Create jenkins-admin service account (serviceaccount.yaml) with Kubernetes admin permissions.
   - Create required access ClusterRole and ClusterRoleBinding for jenkins-master namespace

8. Configure jenkins ingress based on the created nginx-controller for external DNS connectivity. This setup enables external access to Jenkins through the defined hostname, "jenkinsmaster.312centos.com" (previously created route 53 record on AWS console) and it's integrated with an Application Load Balancer (ALB) deployed within EKS. The Ingress resource specifies routing rules and forwards HTTP requests to the "jenkins-svc" service running on port 8080, ensuring seamless access to the Jenkins application. This External DNS (https://github.com/312-bc/devops-tools-23a-centos/blob/MRP23ACENT-18-External-dns/external-dns/README.md#use-external-dns-for-your-ticket) was used to configure Ingress. 


## About the Amazon EBS CSI Driver

The Amazon Elastic Block Store (Amazon EBS) Container Storage Interface (CSI) driver provides a CSI interface that allows Amazon Elastic Kubernetes Service (Amazon EKS) clusters to manage the lifecycle of Amazon EBS volumes for persistent volumes.


## Prerequisites:
1. EKS Cluster, kubectl tool created and installed 
2. Secret created via AWS Console in AWS Secret Manager
3. IAM Role and Policy assosiated with AWS Secret created via AWS console 
4. OIDC Provider is associated with an exisitng EKS cluster 
5. Eksctl tool installed via https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html


1. Install CSI Secrets Store Driver: 

helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver --namespace kube-system --set syncSecret.enabled=true

2. Install Helm via https://docs.aws.amazon.com/eks/latest/userguide/helm.html  

3. Install AWS Secrets and Config Provider 

   kubectl apply -f https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml

 4. Service Account will be associated with Policy we created above. This concept is called IAM Role for Service Account (IRSA).

 5.  Create, deploy AWS Secret Provider Class  ## https://docs.aws.amazon.com/secretsmanager/latest/userguide/integrating_csi_driver_SecretProviderClass.html

 6. Redeploying Statefulset, as its been injected with secrets now. 
 7. Now you can see the secrets mounted on the Pod!!!!


### Jenkins Controller Configured as Code

#### Prerequisites
1. Access to a server with at least 2GB of RAM and Docker installed. This can be your local development machine, a Droplet, or any kind of server. 

The ‘as code’ paradigm is about being able to reproduce and/or restore a full environment within minutes based on recipes and automation, managed as code.

Setting up Jenkins is a complex process, as both Jenkins and its plugins require some tuning and configuration, with dozens of parameters to set within the web UI manage section.

Jenkins Configuration as Code (JCasC) provides the ability to define this whole configuration as a simple, human-friendly, plain text YAML syntax. Without any manual steps, this configuration can be validated and applied to a Jenkins controller in a fully reproducible way.

Starting Jenkins with the configuration file automatically applies settings, making setup quick and reliable. You can restore or replicate Jenkins instances effortlessly, even for testing before production.

 ## link https://github.com/jenkinsci/configuration-as-code-plugin (Official GitHub Page for CASC>>>Folder Demos (i recommend) as it contains examples of commonly used configurations, so some of those pieces you can use for your configuration file )

The configuration file for Jenkins using Jenkins Configuration as Code (JCasC) defines various aspects of Jenkins configuration, including security settings, cloud configurations (for Kubernetes), and tool installations (in this case, Git).


### Setup and manage Jenkins using configuration file.
----------

### Jenkins Controller Configured as Code

The ‘as code’ paradigm is about being able to reproduce and/or restore a full environment within minutes based on recipes and automation, managed as code.

Setting up Jenkins is a complex process, as both Jenkins and its plugins require some tuning and configuration, with dozens of parameters to set within the web UI manage section.

Jenkins Configuration as Code (JCasC) provides the ability to define this whole configuration as a simple, human-friendly, plain text YAML syntax. Without any manual steps, this configuration can be validated and applied to a Jenkins controller in a fully reproducible way.

JCasC makes use of the Configuration as Code plugin, which allows you to define the desired state of your Jenkins configuration as one or more YAML files.

On the initialization, the Configuration as Code plugin will configure Jenkins according to the YAML configuration files.

Create config file jcasc.yaml that will automate the installation and configuration of Jenkins using Docker and jenkins configurationas as code method.

 ### Dockerfile
----------
- Use the jenkins/jenkins:latest as the base image and add all the plugins  that you need. 
- Setup initial wizard disabled.
- Update system dependencies.
- Define the location for the YAML configuration files.
- Copy a file with the list of necessary plugins.
- Copy the YAML configuration file.
- Install all the plugins listed on a file.
- Disabaled the setup Wizard (using the JCAsC eliminates the need to show the setup wizard) - Copy the config-as-code yaml file into the image

We have created a Dockerfile, the plugin list file, and the YAML configuration file. If we build and run the docker image, at this point we will get running a Jenkins instance that has all the plugins installed, disable the setup wizard, and configure the Jenkins URL.

#### Makefile
-----------

Makefile for Building and Pushing Docker Image to AWS ECR
This Makefile simplifies the process of building and pushing a Docker image to Amazon Web Services (AWS) Elastic Container Registry (ECR) for a Jenkins setup. Additionally, it provides targets for creating and deleting the ECR repository, deploying the Kubernetes resources, and cleaning up resources.

## Prerequisites
Docker installed on your local machine.
AWS CLI installed and configured with appropriate IAM permissions.
kubectl configured to work with your Kubernetes cluster.


Issues/Challenges:
Deploying SecretProviderClass due to version incompatibility 
Resolved by adding resources to the cluster 
 
### Useful resources:

---------

https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html 
https://archive.eksworkshop.com/beginner/194_secrets_manager/configure-csi-driver/

- [Project: Declarative Configuration of Jenkins Hands-on session](https://canvas.312.school/courses/66/discussion_topics/2105)
- [Kubernetes Documentation ](https://kubernetes.io/)
- [Jenkins Documentation](https://www.jenkins.io/projects/jcasc/)
- https://www.digitalocean.com/community/tutorials/ how-to-automate-jenkins-setup-with-docker-and-jenkins-configuration-as-code.

External DNS https://github.com/312-bc/devops-tools-23a-centos/blob/MRP23ACENT-18-External-dns/external-dns/README.md#use-external-dns-for-your-ticket
Demos on GitHub for jcasc https://github.com/jenkinsci/configuration-as-code-plugin/tree/master/demos 