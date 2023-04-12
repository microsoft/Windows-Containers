#!/bin/bash

# This shell script demonstrates how to create an Azure storage account and a storage container
# The purpose of the storage container is used for storing the collected trace files
#
# This script is specifically written for Azure AKS environment, but it can be easily modified to run in other vendors' environments
# 
# Key concepts and tools used:
#    1. Interactions between WSL and Windows desktop
#    2. Azure Cli commands for creating Azure Storage account

# Variables
rgName="mydemo"
location="northeurope"
accountName="mydemostorage"
containerName="mydemocontainer"
sasExpiryDate=$(date -u -d '1 day' '+%Y-%m-%dT%H:%MZ')

# Set the default account
az account set --subscription "My Subscription"   

# Create a resource group
az group create --name $rgName --location $location

# Create a storage account
az storage account create --name $accountName --resource-group $rgName --location $location --sku Standard_LRS

# Create containers
az storage container create --name $containerName \
 --account-name $accountName \
 --account-key $(az storage account keys list --resource-group $rgName --account-name $accountName --query "[0].value" -o tsv)




