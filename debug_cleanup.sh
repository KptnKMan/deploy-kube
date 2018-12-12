#!/bin/bash

## Delete existing current certs
rm -Rf config/ssl

## Delete existing current config files
rm -Rf config/kubeconfig

## Delete terraform state files
rm -Rf terraform.tfstate
rm -Rf terraform.tfstate.backup

## Delete deploys
rm -Rf deploys
