
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
#    7. NPM: Network Policy Manager

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
declare -g sastoken=""

#node name defined in the create cluster.sh
nodename=wnode

hostprocesspod=hostsysprocess 

#set up alias as shortcuts
k=kubectl
kex="$k exec -n x"
kax="$k apply -n x"
klpx="$k label pod -n x"
hostprocesspod=hostsysprocess
kexhost="$k exec $hostprocesspod --"

CreateHostProcessContainer()
{
    #get all the pods on the current cluster before host process container
    $k get pods -A

    #Create host process container in the default name space
    $k label nodes aks"$nodename"000000 vm=0
    $k delete pod $hostprocesspod
    $k apply -f ./yaml/$hostprocesspod.yaml --wait
    $k wait --for=condition=Ready --all --timeout -1s pod

    #get all the pods on the current cluster after host process container
    $k get pods -A
}

StartPerfTrace()
{
    #Start collecting traces with etw providers
    $k exec $hostprocesspod -- wpr.exe -start "c:\\Program Files\\Containerd\\containerplatform.wprp" -start cpu -start diskio -start fileio -compress -skipPdbGen -recordtempto d:\\perf
}

DownloadNeededFiles() 
{
    echo "create d:\perf folder"
    $kexhost cmd.exe /C md d:\\perf

    echo "copy azcopy.exe to the target node d:\perf folder"
    $k cp azcopy.exe $hostprocesspod:d:/perf/azcopy.exe
    $k cp ./traceprofiles/ContainerPlatform.wprp $hostprocesspod:d:/perf/ContainerPlatform.wprp
    $k cp ./traceprofiles/system.wprp $hostprocesspod:d:/perf/system.wprp   
    $k cp Switchport.ps1 $hostprocesspod:d:/perf/Switchport.ps1
}

testDeny()
{
    MAX_ROUNDS=$((12 * 5)) # 3 minutes
    round=1
    while [[ $round -le $MAX_ROUNDS ]];
    do
        $kex b -c cont-80-tcp -- /agnhost connect s-a.x.svc.cluster.local:80 --timeout=5s --protocol=tcp
        if [[ $? -ne 0 ]]; then
            echo "Applied the policy connection return $? b->a. denied"
            return 1
        fi
        $kex b -c cont-80-tcp -- /agnhost connect s-a.x.svc.cluster.local:80 --timeout=5s --protocol=tcp
        echo "sleeping 3 seconds after round $round  return $?"
        sleep 3
        round=$(($round + 1))
    done
}

testAllow()
{
    MAX_ROUNDS=$((12 * 5)) # 3 minutes
    round=1
    while [[ $round -le $MAX_ROUNDS ]];
    do
        $kex b -c cont-80-tcp -- /agnhost connect s-a.x.svc.cluster.local:80 --timeout=5s --protocol=tcp
        if [[ $? == 0 ]]; then
            echo "connection return $? b->a. allowed"
            return 0
        fi
        $kex b -c cont-80-tcp -- /agnhost connect s-a.x.svc.cluster.local:80 --timeout=5s --protocol=tcp
        echo "sleeping 3 seconds after round $round return $?"
        sleep 3
        round=$(($round + 1))
    done
}


GetSwitchPortMappings() 
{
    filename=$1
    portmapping=d:\\perf\\$filename
    echo "delete the existing port mapping log files"
    $kexhost cmd.exe /C del /Q d:\\perf\\*.log

    echo "get current switch port settings"
    $kexhost Powershell.exe d:\\perf\\Switchport.ps1

    echo "compress the switch port settings"
    $kexhost Powershell.exe compress-archive d:\\perf\\*.log $portmapping -force

    echo "upload port mapping file"
    UploadFile $filename 
    DownloadFile $filename 
}

GetResults() 
{
    reslutfilename=$1
    StopPerfTrace $reslutfilename.etl    
    GetSwitchPortMappings $reslutfilename.zip
    UploadFile $reslutfilename.etl
    DownloadFile $reslutfilename.etl
}

ScenarioRepro()
{
    GetSwitchPortMappings DefaultPolicy.zip

    echo "==================prepare policy pods======================"

    StartPerfTrace

    $k apply -n x -f ./yaml/test-3-minimal-agnhost-pods.yaml --wait
    $k wait --for=condition=Ready --all --timeout -1s pod
   
    echo "------------------------End prepare policy pods--------------------------"

    echo "1 ========================Start Default network allow b->a ========================"

    
    $kex b -- echo "Start Default network allow b->a"
    $kex b -c cont-80-tcp -- /agnhost connect s-a.x.svc.cluster.local:80 --timeout=5s --protocol=tcp
    testAllow
    $kex b -- echo "End Default connection return $? b->a allowed"

    echo "1 ------------------------End Default connection return $? b->a allowed"

    echo "2 ====================== Strt Default network allow c->a =========================="

    $kex c -- echo "Start Default network allow c->a"
    $kex c -c cont-80-tcp -- /agnhost connect s-a.x.svc.cluster.local:80 --timeout=5s --protocol=tcp
    testAllow

    GetResults afterpoddeployment

    $kex c -- echo "End Default connection return $? c->a allowed"

    echo "2 ---------------------- End Default connection return $? c->a allowed"

    echo "3 ===================Start Apply the nework policy b->a blocked ==================="
    StartPerfTrace

    $kex c -- echo "Start Apply the nework policy b->a blocked"
    $kax -f ./yaml/policy-ingress-access-from-updated-pod.yaml
    testDeny
    $kex b -- echo "End Applied the policy connection return $? b->a. denied"

    GetResults applypolicy

    echo "3 -------------------End Applied the policy connection return $? b->a. denied"


    echo "4 ==================Start Label the Pod to allow the traffic b->a allowed ========="
    StartPerfTrace

    $kex c -- echo "Start Label the Pod to allow the traffic b->a allowed"
    $klpx b pod2=updated
    testAllow
    $kex b -- echo "End Labeled the policy connection return $? b->a. allowed"

    GetResults labelPod

    echo "4 ------------------End Labeled the policy connection return $? b->a. allowed"

    echo "5 ===================Start Unlabled the Pod b->a denied====================================="
    StartPerfTrace

    $kex c -- echo "Start Unlabled the Pod b->a denied"
    $klpx b pod2-
    testDeny
    $kex b -- echo "End Removed the label the policy connection return $? b->a. denied"

    GetResults unlabelPod

    echo "5 -------------------End Removed the label the policy connection return $? b->a. denied"

    echo "6 =================== Start Delete Policy b->a allowed ======================================"

    StartPerfTrace

    $kex c -- echo "Start Delete Policy b->a allowed"
    kubectl delete -n x -f ./yaml/policy-ingress-access-from-updated-pod.yaml
    testAllow
    $kex b -- echo "End Removed the policy connection return $? b->a. allowed"

    GetResults removepolicy

    echo "6 --------------------End Removed the policy connection return $? b->a. allowed"


}

StopPerfTrace()
{
    tracefile=$1
    #Stop collecting traces 
    $k exec $hostprocesspod -- wpr.exe -stop d:\\perf\\$tracefile 
}

GetStorageSASToken()
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
}

UploadFile()
{
    fileToUpload=$1
    # Combine the URL, share name, and file path to get the full URL path
    echo "containerName: ${storageAccountContainerName}"
    echo "fileToUpload: ${fileToUpload}"
    echo "sas_token: ${sastoken}"

    full_url="https://${storageAccountName}.blob.core.windows.net/${storageAccountContainerName}/${fileToUpload}?${sastoken}"

    echo $full_url    

    #copy the trace to the storage share
    $k exec $hostprocesspod -- d:\\perf\\azcopy.exe cp  d:\\perf\\$fileToUpload "${full_url}" 
    
    #delete the uploaded file
    $k exec $hostprocesspod -- cmd.exe del /Q d:\\perf\\$fileToUpload
}

DownloadFile()
{
    fileToDownload=$1
    #download trace to my local volume
    echo "containerName: ${storageAccountContainerName}"
    echo "fileToUpload: ${fileToUpload}"
    echo "sas_token: ${sastoken}"

    download_url="https://${storageAccountName}.blob.core.windows.net/${storageAccountContainerName}/${fileToDownload}?${sastoken}"    
    azcopy cp "${download_url}" ./results/$fileToDownload
}

Cleanup()
{
    $k delete ns chaos-jr --wait
    $k -n chaos-jr wait --for=condition=Delete --all --timeout -1s pod
    $k delete ns x --wait
    $k -n x wait --for=condition=Delete --all --timeout -1s pod   
    $k delete ns test --wait
    $k -n test wait --for=condition=Delete --all --timeout -1s pod       
    $k create ns x
}

# Set the default account
az account set --subscription "${subscription}" 

#step 1  
Cleanup

#step 2  
GetStorageSASToken

#step 3  
CreateHostProcessContainer

#step 4
DownloadNeededFiles

#step 5
ScenarioRepro