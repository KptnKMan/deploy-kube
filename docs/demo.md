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

If you just want to copy/paste all the commands, here they are:

```bash
kubectl --kubeconfig=config/kubeconfig apply -f deploys/deploy_base_kubedns.yaml
kubectl --kubeconfig=config/kubeconfig apply -f deploys/deploy_base_dashboard.yaml
kubectl --kubeconfig=config/kubeconfig apply -f deploys/deploy_base_efs_storageclaim.yaml
kubectl --kubeconfig config/kubeconfig apply -f deploys/deploy_demo_traefik_whoami_app.yaml
helm init
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
acme.staging=false,\
acme.logging=enabled,\
acme.domains.enabled=true,\
acme.domains.domainList.main=*.mydomain.com,\
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

### Setup Ingress

Options are using default nginx ingress or traefik ingress.

#### Nginx Ingress

```bash
kubectl --kubeconfig config/kubeconfig apply -f deploys/deploy_base_ingress_controller.yaml
```

##### Traefik Ingress using Helm

Traefik whoami demo app (optional):

```bash
kubectl --kubeconfig config/kubeconfig apply -f deploys/deploy_demo_traefik_whoami_app.yaml
```

Without LetsEncrypt SSL:

```bash
helm install stable/traefik \
    --set dashboard.enabled=true,\
    dashboard.domain=kareempoc-traefik.mydomain.com,\
    service.nodePorts.http=32004,service.nodePorts.https=32005,serviceType=NodePort \
    --name traefik-ingress
```

With LetsEncrypt:

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
acme.staging=false,\
acme.logging=enabled,\
acme.domains.enabled=true,\
acme.domains.domainList.main=*.mydomain.com,\
acme.persistence.enabled=false
```

### Install Rancher

TBC
