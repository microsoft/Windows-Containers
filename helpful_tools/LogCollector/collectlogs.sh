
#!/bin/bash

# This shell script demonstrates how to use a host process container to collect
# zipped log file generated from c:\k\debug\collect-windows-logs.ps1 command
# 
# After the script finishes executing, the captured logs will be stored in ./results/latestdebuglog.zip

# Key concepts and tools used:
#    1. `kubectl` to deploy pods and label nodes
#    2. Host process containers
#    3. `azcopy.exe` to upload and download collected trace files
#    4. Interactions between WSL and Windows desktop


# ========= Variables==========
# storage account for uploading collected trace files
rgName="kubedemo"
location="northeurope"
accountName="kubecondemostorage"
containerName="kebecondemocontainer"
sasExpiryDate=$(date -u -d '1 day' '+%Y-%m-%dT%H:%MZ')

# Define the global variable full_url as azcopy.exe target
declare -g sastoken=""


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


CollectClusterLogs()
{
    
    #Create d:\perf folder to collect traces
    $k exec $hostprocesspod -- cmd.exe md d:\\perf

    #sleep for 30 seconds
    sleep 30    

    $k cp ./collectlog.ps1 hostsysprocess:d:\\perf\collectlog.ps1
    
    
    #Create d:\perf folder to collect traces
    $k exec $hostprocesspod -- C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\PowerShell.exe d:\\Perf\collectlog.ps1

    GetStorageSASToken

    full_url="https://${accountName}.blob.core.windows.net/${containerName}/latestdebuglog.zip?${sastoken}"

    #copy the trace to the storage share
    $k exec $hostprocesspod -- d:\\perf\\azcopy.exe cp  d:\\perf\\latestdebuglog.zip "${full_url}" 
    azcopy cp "${full_url}" ./results/latestdebuglog.zip

}

GetStorageSASToken()
{
    accountkey=$(az storage account keys list \
        --resource-group $rgName \
        --account-name $accountName \
        --query "[0].value" -o tsv)

    # Generate a SAS token for the container
    sastoken=$(az storage container generate-sas \
        --account-name ${accountName} \
        --account-key ${accountkey} \
        --name $containerName \
        --permissions "rwdl" \
        --expiry $sasExpiryDate \
        --https-only \
        --output tsv)    
}

# Set the default account
az account set --subscription "My Subscription" 
#step 1  
CreateHostProcessContainer
#step 2
CollectClusterLogs
