#!/bin/bash

# This shell script demonstrates how to create an Azure AKS cluster, plus a windows node
#
# This script is specifically written for Azure AKS environment, but it can be easily modified to run in other vendors' environments
# 
# Key concepts and tools used:
#    1. `kubectl` to deploy pods and label nodes
#    2. Interactions between WSL and Windows desktop
#    3. Azure Cli commands

clustername=mydemo
resourcegroup=mydemorg 
username=mydemoadmin
pwd=mypassword
location=northeurope
nodename=wnode
k8sversion="1.25.5"

# set the default subscription
az account set --subscription "My Subscription"

# delete cluster if it exists
#az aks delete --name $clustername --resource-group $resourcegroup --yes   

# create resource group
az group create --name $resourcegroup --location $location

# Create cluster based on specified parameters
az aks create \
    --resource-group $resourcegroup \
    --name $clustername \
    --generate-ssh-keys \
    --windows-admin-username $username \
    --windows-admin-password $pwd \
    --kubernetes-version $k8sversion \
    --network-plugin azure \
    --vm-set-type VirtualMachineScaleSets \
    --node-count 1 \
    --max-pods 200 \
    --network-policy azure \
    --uptime-sla 

# Create a Windows Server 2022 cluster node
az aks nodepool add \
    --resource-group $resourcegroup \
    --cluster-name $clustername \
    --name $nodename \
    --os-type Windows \
    --os-sku Windows2022 \
    --max-pods 200 \
    --node-count 1

# Retrieve the newly created cluster credentials
az aks get-credentials --resource-group $resourcegroup --name $clustername --overwrite-existing
