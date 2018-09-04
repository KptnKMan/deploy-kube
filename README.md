# Kareems New Kubernetes

This repository contains Kareems New Kubernetes Deployment configuration.
This is designed to bring up a cluster in AWS (Amazon Web Services) that is empty and ready to manipulate.
This is intended to eventually reflect production-ready implementation.
Currently it is in testing, and may not work.

It contains:

* (WIP) Documentation for setup and management
* (WIP) Deployment Cluster (Kubernetes)
* (TBC) Production Cluster (Kubernetes)
* (TBC) Scripts to create and update infrastructure
* (TBC) Default configuration and settings to build environment

Additional documentation for setup can be found in [docs](docs), when they become available.

Best to start at the [Setup doc](docs/setup.md) to setup an environment.

## Basic Requirements

* kubectl 1.10.6+
* Terraform 0.11.7
* Ansible 2.4.1.0+
* an ssh public/private keypair in /config dir

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

## Todos & Known issues

* security
  * [ ] find better way for SSL cert distribution
    * encrypted S3?
    * hashicorp vault?
    * simple DB storage?
  * [ ] paramaterise SSL .cnf template
  * [x] translate SSL provisioning to terraform native
  * [ ] terraform provision instance SSH keypair
* documentation
  * [ ] setup doc with example cli commands
  * [ ] demo doc with example cli commands
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
  * [ ] figure out friggin v1.8.x RBAC!
  * [ ] RBAC: get basic roles organised/documented
  * [ ] RBAC: get kubelet node role organised (requires at-deploy provisioning certs)
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
  * [ ] Create working demo of Kube services including ELB-ingress
    * [x] core services - kube-dns & dashboard
    * [ ] ingress demo - basic
    * [ ] ingress demo - host-based routing
    * [ ] ingress demo - kube-ingress-aws
      * [ ] kube-ingress-aws IAM policy
