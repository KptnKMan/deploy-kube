# Deploy-Kube Setup Doc

This doc is intended to:

* Help you help you bootstrap a working Kubernetes environment using the Terraform code in this repo.

## Notes - PLEASE READ

* Currently, nearly all setup details are identical to those in the [base vpc template setup doc](https://github.com/KptnKMan/deploy-vpc-aws/blob/master/docs/setup.md).
* Any contradiction of requirements/instructions, use the child templates (THIS TEMPLATE IS A CHILD TEMPLATE) instructions.

## Setup Tools

### Setup Terraform

Follow details in [this part of the base vpc template setup doc](https://github.com/KptnKMan/deploy-vpc-aws/blob/master/docs/setup.md#setup-tools).

### Setup kubectl

Linux:
```
sudo curl -L https://storage.googleapis.com/kubernetes-release/release/v1.12.2/bin/linux/amd64/kubectl -o /usr/bin/kubectl
sudo chmod +x /usr/bin/kubectl
```
MacOS:
```
sudo curl -L https://storage.googleapis.com/kubernetes-release/release/v1.12.2/bin/darwin/amd64/kubectl -o /usr/local/bin/kubectl
sudo chmod +x /usr/local/bin/kubectl
```
Windows:
```
Invoke-WebRequest -Uri http://storage.googleapis.com/kubernetes-release/release/v1.12.2/bin/windows/amd64/kubectl.exe -Outfile $HOME\Downloads\kubectl.exe
Move-Item $HOME\Downloads\kubectl.exe $env:SystemRoot
```

## Setup Environment Variables

Follow details in [this part of the base vpc template setup doc](https://github.com/KptnKMan/deploy-vpc-aws/blob/master/docs/setup.md#setup-environment-variables).

## Creating and Updating infrastructure

Follow details in [this part of the base vpc template setup doc](https://github.com/KptnKMan/deploy-vpc-aws/blob/master/docs/setup.md#creating-and-updating-infrastructure).

## Connecting to resources

Follow details in [this part of the base vpc template setup doc](https://github.com/KptnKMan/deploy-vpc-aws/blob/master/docs/setup.md#setup-tools#connecting-to-resources).

## Create full-featured environment

Example details of spinning up an example functioning and working cluster will be in the [demo doc](demo.md).

## Cleanup

### Notes

* Remember to tear down this environment before the base vpc template.

### Tear down environment

Follow details in [this part of the base vpc template setup doc](https://github.com/KptnKMan/deploy-vpc-aws/blob/master/docs/setup.md#cleanup).
