# Demo Notes

This doc is intended to:

* Show and explain the commands for a working demo environment.

## Notes - PLEASE READ

* You will want to read the [base vpc setup doc](https://github.com/KptnKMan/deploy-vpc-aws/docs/setup.md) and [this repos setup doc](docs/setup.md) before this document.
* This document assumes that you have already setup a functioning cluster according to the setup docs.
* Unless specified, all commands are run from root of repo directory
  * Eg: `cd ~/Projects/deploy-vpc-aws)` (but your root dir is very likely to be different)

## TL:DR commands

If you just want to copy/paste all the commands, here they are:

```bash
kubectl -kubectl=config/kubeconfig apply -f deploys/deploy_kubedns.yaml
kubectl -kubectl=config/kubeconfig apply -f deploys/deploy_dashboard.yaml
```

## Commands explanation

A more detailed explanation of commands:

TBC