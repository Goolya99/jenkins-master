# Makefile for building and pushing Docker image to AWS ECR

# Variables
repo := jenkins-master
version := jenkins-jcasc-centos
region := us-east-1
namespace := jenkins-master
account := $(shell aws sts get-caller-identity --output text --query 'Account')
image := 23a-jenkins-master
service := jenkins

# Docker build target
build:
	docker build --platform=linux/amd64 -t $(image):$(version) .

# Docker login target
login:
	aws ecr get-login-password --region $(region) | docker login --username AWS --password-stdin $(account).dkr.ecr.$(region).amazonaws.com

# Docker push target
push: login
	docker tag $(image):$(version) $(account).dkr.ecr.$(region).amazonaws.com/$(repo):$(version)
	docker push $(account).dkr.ecr.$(region).amazonaws.com/$(repo):$(version)

# create the ECR repository
create-repo:
	aws ecr create-repository --repository-name $(repo) --region $(region)

deploy:
	kubectl apply -f ./k8s/namespace.yaml
	kubectl apply -f ./k8s/

### Clean-Up 

repo-delete:
	aws ecr delete-repository \
    --repository-name $(repo) \
	--region $(region) \
    --force

namespace-delete:
	cat namespace.yaml | sed "s/NAMESPACE/$(namespace)/g" | kubectl delete -f -

delete-deploy:
	kubectl delete -f ./k8s/namespace.yaml --grace-period=0 --force


