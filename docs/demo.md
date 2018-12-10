# Demo Notes

This doc is intended to:

* Show and explain the commands for a working demo environment.
  * Setup cluster base
  * Helm (Tiller)
  * Setup Ingress
  * Rancher

## Notes - PLEASE READ

* You will want to read the [base vpc setup doc](https://github.com/KptnKMan/deploy-vpc-aws/docs/setup.md) and [this repos setup doc](docs/setup.md) before this document.
* This document assumes that you have already setup a functioning cluster according to the setup docs.
* Unless specified, all commands are run from root of repo directory
  * Eg: `cd ~/Projects/deploy-vpc-aws)` (but your root dir is very likely to be different)

## Setup Tools

This demo installation requires a few tools:

* Helm
* Rancher

## TL:DR commands

Note: This assumes AWS Route53, and you will need to change these params below:

* `dashboard.domain`
* `acme.email`
* `staging`
* `acme.domains.domainList.main`
* `acme.domains.domainList.sans`

If you just want to copy/paste all the commands, here they are:

```bash
# deploy base templates
kubectl --kubeconfig=config/kubeconfig apply -f deploys/deploy_base_kubedns.yaml
kubectl --kubeconfig=config/kubeconfig apply -f deploys/deploy_base_dashboard.yaml
kubectl --kubeconfig=config/kubeconfig apply -f deploys/deploy_base_efs_storageclaim.yaml
helm init

# deploy test app
kubectl --kubeconfig config/kubeconfig apply -f deploys/deploy_demo_whoami_app.yaml

# wait ~20 seconds
# deploy traefik ingress using helm
helm install stable/traefik \
--name traefik-ingress \
--set imageTag=1.7.4,\
dashboard.enabled=true,\
dashboard.domain=kareempoc-traefik.mydomain.com,\
service.nodePorts.http=32004,service.nodePorts.https=32005,serviceType=NodePort,\
ssl.enabled=true,\
ssl.enforced=false,\
acme.enabled=true,\
acme.challengeType=dns-01,\
acme.dnsProvider.name=route53,\
acme.email=some.email@myemail.com,\
acme.staging=true,acme.logging=enabled,\
acme.domains.enabled=true,\
acme.domains.domainList.main=*.mydomain.com,\
acme.domains.domainList.sans=mydomain.com,\
acme.persistence.enabled=false
```

## Commands explanation

A more detailed explanation of commands:

### Setup Cluster Base

```bash
kubectl --kubeconfig=config/kubeconfig apply -f deploys/deploy_base_kubedns.yaml
kubectl --kubeconfig=config/kubeconfig apply -f deploys/deploy_base_dashboard.yaml
kubectl --kubeconfig=config/kubeconfig apply -f deploys/deploy_base_efs_storageclaim.yaml
```

### Install Helm (Tiller)

[Details for installing helm](https://docs.helm.sh/using_helm/#installing-helm)
After installing Helm, to install Tiller you need to run:

```bash
helm init
```

### Setup Ingress Controller and auto-TLS

Options are using Traefik Ingress Controller or Nginx Ingress Controller.

#### Traefik Ingress Controller using rendered deploy

TBC

#### Traefik Ingress Controller using Helm

* https://docs.traefik.io/configuration/acme/#wildcard-domain
* https://docs.traefik.io/user-guide/examples/#lets-encrypt-support
* https://docs.traefik.io/basics/*

Traefik whoami demo app (optional):

```bash
kubectl --kubeconfig config/kubeconfig apply -f deploys/deploy_demo_whoami_app.yaml
```

Without LetsEncrypt SSL:

```bash
helm install stable/traefik \
--name traefik-ingress \
--set dashboard.enabled=true,\
dashboard.domain=kareempoc-traefik.bifromedia.com,\
service.nodePorts.http=32004,service.nodePorts.https=32005,serviceType=NodePort
```

With LetsEncrypt, using AWS Route53 DNS:

```bash
helm install stable/traefik \
--name traefik-ingress \
--set imageTag=1.7.4,\
dashboard.enabled=true,\
dashboard.domain=kareempoc-traefik.mydomain.com,\
service.nodePorts.http=32004,service.nodePorts.https=32005,serviceType=NodePort,\
ssl.enabled=true,\
ssl.enforced=false,\
acme.enabled=true,\
acme.challengeType=dns-01,\
acme.dnsProvider.name=route53,\
acme.email=some.email@myemail.com,\
acme.staging=true,acme.logging=enabled,\
acme.domains.enabled=true,\
acme.domains.domainList.main=*.mydomain.com,\
acme.domains.domainList.sans=mydomain.com,\
acme.persistence.enabled=false
```

#### Nginx Ingress Controller using rendered deploy

```bash
kubectl --kubeconfig config/kubeconfig apply -f deploys/deploy_base_ingress_controller.yaml
```

#### Nginx Ingress Controller using Helm

* https://github.com/kubernetes/ingress-nginx
* https://cert-manager.readthedocs.io/en/latest/tutorials/acme/securing-nginx-ingress-with-letsencrypt.html

```bash
# install nginx ingress controller
helm install stable/nginx-ingress \
--name nginx-ingress \
--namespace kube-system \
--set image.tag=0.20.0,\
controller.service.type=NodePort,\
controller.service.nodePorts.http=32004,\
controller.service.nodePorts.https=32005,\
ServiceAccount.Create=true,\
rbac.create=true
```

* https://github.com/jetstack/cert-manager
* https://cert-manager.readthedocs.io/en/latest/reference/ingress-shim.html
* https://cert-manager.readthedocs.io/en/latest/reference/certificates.html
* https://cert-manager.readthedocs.io/en/latest/reference/issuers.html
* https://cert-manager.readthedocs.io/en/latest/reference/clusterissuers.html

```bash
# install cert-manager using helm
helm install stable/cert-manager \
--name cert-manager \
--namespace kube-system \
--set image.tag=v0.4.1,\
rbac.create=true,\
serviceAccount.create=true

# install cert-manager Certificate request
kubectl --kubeconfig config/kubeconfig apply -f deploys/deploy_demo_certmgr_certreq.yaml
# install cert-manager ClusterIssuers
kubectl --kubeconfig config/kubeconfig apply -f deploys/deploy_demo_certmgr_issuer.yaml
```

### Install Rancher

TBC
