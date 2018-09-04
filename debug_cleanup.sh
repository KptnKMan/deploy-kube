#!/bin/bash

## Delete existing current certs
rm -Rf config/ssl

## Delete existing current config files
rm -Rf config/kubeconfig

## Delete terraform state files
rm -Rf config/cluster.state
rm -Rf config/cluster.state.backup

## Delete deploys
rm -Rf deploys
