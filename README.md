# Kareems New Kubernetes

This repository contains Kareems New Kubernetes Deployment configuration.
It's designed to use outputs from and be built on top of the base Terraform [Base VPC and Bastion Deployment template](https://github.com/KptnKMan/deploy-vpc-aws).
This is designed to bring up a cluster in AWS (Amazon Web Services) that is empty and ready to manipulate.
This is intended to eventually reflect production-ready implementation.
Currently it is in testing, and may not work.

It contains:

* [x] Documentation for setup and management
* [x] Deployment Kubernetes Cluster
* [ ] Default configuration and settings to build environment
* [x] Scripts to create, update and cleanup infrastructure
* [ ] Demo details of things to do with Kubernetes

Additional documentation for setup can be found in [docs](docs), when they become available.

Best to start at the [Setup doc](https://github.com/KptnKMan/deploy-vpc-aws/docs/setup.md) to setup an environment.

## Basic Requirements

* kubectl 1.10.6+
* Terraform 0.11.7
* ~~Ansible 2.4.1.0+~~
* ~~an ssh public/private keypair in /config dir~~
  * the ssh-keypair name is inherited from the output of the parent base vpc template.
  * the ssh-keypair will be auto-generated into the /config dir of the base vpc template.

## Main Components

* Diagram

TBC

* AWS

VPC
Internet Gateway
Route Tables
Subnets
S3 Buckets
EFS storage
Route53 DNS
ASG Controller
ASG ETCD
ASG Worker

* Master/Controller Server

docker-bootstrap.service
flannel.service
kube-apiserver.service
kube-controller-manager.service
kube-scheduler.service
kube-proxy.service

* Etcd Server

docker.service
etcd.service (now etcd3 :) )
cfn-signal.service

* Worker Nodes

docker-bootstrap.service
flannel.service
docker.service
kubelet.service
kube-proxy.service

## Notes

Versions tested:

* kubectl: 1.10.6 In testing: 1.11.x
* terraform: 0.8.8 upto 0.11.7
* ansible-playbook: 2.2.1.0, 2.4.1.0

Terraform Inputs:

* This template will accept and require a number of outputs from the base template.
* You will want to deploy the [base template](https://github.com/KptnKMan/deploy-vpc-aws) first.

## Todos & Known issues

* security
  * [ ] find better way for SSL cert distribution
    * encrypted S3?
    * hashicorp vault?
    * simple DB storage?
  * [x] paramaterise SSL .cnf template
  * [x] translate SSL provisioning to terraform native
  * [x] terraform provision instance SSH keypair
* documentation
  * [ ] setup doc with example cli commands
  * [ ] demo doc with example cli commands
  * [ ] Create working demo of Kube services including ELB-ingress
    * [x] core services - kube-dns & dashboard
    * [ ] ingress demo - basic
    * [ ] ingress demo - host-based routing
    * [ ] ingress demo - kube-ingress-aws
      * [ ] kube-ingress-aws IAM policy
* etcd concerns
  * [x] resolve etcd provisioning
  * [x] update etcd to latest 3.x+
  * [ ] etcd backups
  * [ ] rebuild etcd image with open logic
  * [x] etcd-aws-py docker-image ready
  * [ ] etcd-aws-go docker-image ready
* kubernetes
  * [x] update kube to latest 1.8.x
  * [x] update kube to latest 1.10.6 stable
  * [ ] update kube to latest 1.10.x stable (1.10.7)
  * [ ] update kube to latest 1.11.x stable (1.11.2)
  * [ ] update kube to latest 1.x.x beta (1.12.0-beta.0)
  * [ ] update kube to latest 1.x.x alpha (1.13.0-alpha.0)
  * [ ] cluster autoscaling (cluster-autoscaler?) (kube-aws-autoscaler?)
    * [ ] autoscaler IAM policy
  * [x] figure out friggin v1.8.x RBAC!
  * [ ] RBAC: get basic roles organised/documented
  * [x] RBAC: get kubelet node role organised (requires at-deploy provisioning certs)
* terraform
  * [x] update terraform to latest 10.x
  * [ ] update terraform to latest 11.x
  * [ ] Fix some terraform code inconstencies
  * [ ] translate etcd/controller/worker ASGs to terraform native
* AWS-specific
  * [ ] all security groups tightened
  * [ ] secure ability to expose API server for multi-cloud
  * [ ] test multi-cloud deployment
* Azure-specific
  * [ ] develop multi-cloud extension
* Google-specific
  * [ ] develop multi-cloud extension
* other
  * [x] FYI: Kube 1.8.x worker kubelet requires "--kube-swap-on=false" as swap is undesired.
