
#!/bin/bash

# This shell script demonstrates how to use a host process container to collect
# ETW events for troubleshooting reliability and performance issues in Windows containers.
#
# This script is specifically written for Azure AKS environment, but it can be easily modified to run in other vendors' environments
# 
# Key concepts and tools used:
#    1. `kubectl` to deploy pods and label nodes
#    2. Host process containers
#    3. ETW trace event collection with wpr.exe
#    4. `azcopy.exe` to upload and download collected trace files
#    5. Interactions between WSL and Windows desktop
#    6. WPA to exame the collected etl file.

# By pass sudo command password
# sudo nano /etc/sudoers
# Insert the following line to sudoers
#  <username> ALL=(ALL) NOPASSWD:ALL

# ========= Variables==========
# storage account for uploading collected trace files
storageAccountResourceGroupName=$1
storageAccountlocation=$2
storageAccountName=$3
storageAccountContainerName=$4
subscription=$5
sasExpiryDate=$(date -u -d '1 day' '+%Y-%m-%dT%H:%MZ')

# Define the global variable full_url as azcopy.exe target
declare -g full_url=""

#The trace file name
tracefile="mysenariotrace.etl"

#node name defined in the create cluster.sh
nodename=wnode

hostprocesspod=hostsysprocess 

#set up alias as shortcuts
k=kubectl

CreateHostProcessContainer()
{
    #get all the pods on the current cluster before host process container
    $k get pods -A

    #Create host process container in the default name space
    $k label nodes aks"$nodename"000000 vm=0
    $k delete pod $hostprocesspod
    $k apply -f ./$hostprocesspod.yaml --wait
    $k wait --for=condition=Ready --all --timeout -1s pod

    #get all the pods on the current cluster after host process container
    $k get pods -A
}

StartCollectingTraces()
{
    #Create d:\perf folder to collect traces
    $k exec $hostprocesspod -- cmd.exe md d:\\perf

    #sleep for 30 seconds
    sleep 30

    #Start collecting traces with etw providers
    $k exec $hostprocesspod -- wpr.exe -start "c:\\Program Files\\Containerd\\containerplatform.wprp" -start cpu -start diskio -start fileio -compress -skipPdbGen -recordtempto d:\\perf
}

ScenarioRepro()
{
    $k apply -f myscenario.yaml
}

StopCollectingTraces()
{
    #Stop collecting traces 
    $k exec $hostprocesspod -- wpr.exe -stop d:\\perf\\$tracefile 
}

GetStorageShareURL()
{
    accountkey=$(az storage account keys list \
        --resource-group $storageAccountResourceGroupName \
        --account-name $storageAccountName \
        --query "[0].value" -o tsv)

    # Generate a SAS token for the container
    sastoken=$(az storage container generate-sas \
        --account-name ${storageAccountName} \
        --account-key ${accountkey} \
        --name $storageAccountContainerName \
        --permissions "rwdl" \
        --expiry $sasExpiryDate \
        --https-only \
        --output tsv)

    # Combine the URL, share name, and file path to get the full URL path
    echo "containerName: ${storageAccountContainerName}"
    echo "tracefile: ${tracefile}"
    echo "sas_token: ${sastoken}"

    full_url="https://${storageAccountName}.blob.core.windows.net/${storageAccountContainerName}/${tracefile}?${sastoken}"

    echo $full_url
}

UploadingTraces()
{
    #copy azcopy.exe to the target node with host process container
    $k cp ./azcopy.exe $hostprocesspod:d:/perf/azcopy.exe
    GetStorageShareURL

    #copy the trace to the storage share
    $k exec $hostprocesspod -- d:\\perf\\azcopy.exe cp  d:\\perf\\$tracefile "${full_url}" 
    
    #delete d:\perf folder to collect traces
    #$k exec $hostprocesspod -- cmd.exe delete /Y d:\\perf
}

DownloadingTraces()
{
    #download trace to my local volume
    azcopy cp "${full_url}" ./results/$tracefile
}


# Set the default account
az account set --subscription "${subscription}" 
#step 1  
CreateHostProcessContainer
#step 2
StartCollectingTraces
#step 3
ScenarioRepro
#step 4
StopCollectingTraces
#step 5
UploadingTraces
#step 6
DownloadingTraces