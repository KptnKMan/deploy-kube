# Deploy-Kube Setup Doc

This doc is intended to:

* Help you help you bootstrap a working Kubernetes environment using the Terraform code in this repo.

## Notes - PLEASE READ

* Currently, nearly all setup details are identical to those in the [base vpc template setup doc](https://github.com/KptnKMan/deploy-vpc-aws/blob/master/docs/setup.md).
* Any contradiction of requirements/instructions, use the child templates (THIS TEMPLATE IS A CHILD TEMPLATE) instructions.
* Pay attention to versions used. Use latest at your own risk.
* Unless specified, all commands are in bash (Linux/MacOS) or Powershell v4+ (Windows), make sure your OS and package mgmt tool is updated (Eg: `apt-get update`)
* MacOS is assumed to be MacOSX (MacOS 10.12.6 tested)
* Linux is assumed to be Ubuntu 16.04
* Windows is assumed to be Microsoft Windows 10
* Unless specified, all commands are run from root of repo directory
  * Eg: `cd ~/Projects/deploy-kube)` (but your root dir is very likely to be different)
* Remember to tear down this environment before the base vpc template.

## TL;DR / Quickstart

Here are the quick start instructions, using bash:

```bash
# setup variables
export TF_VAR_aws_access_key=AKIYOURACCESSKEYHERE
export TF_VAR_aws_secret_key=kTHISISWHEREYOUPUTYOURAWSSECRETKEYHEREt1
export TF_VAR_aws_region=eu-west-1

# setup TF environment
terraform get terraform
terraform init terraform
terraform plan terraform
terraform apply terraform

# destroy environment
terraform destroy terraform

# cleanup
./debug_cleanup.sh
```

More detailed instructions are below.

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

### Extra Notes

* Remember to tear down this environment before the base vpc template.

### Tear down environment

Follow details in [this part of the base vpc template setup doc](https://github.com/KptnKMan/deploy-vpc-aws/blob/master/docs/setup.md#cleanup).
