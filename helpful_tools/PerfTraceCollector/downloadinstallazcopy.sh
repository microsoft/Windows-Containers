#!/bin/bash

# This shell script demonstrates how to download azcopy.exe on the local volume, then
# copy to the AKS windows node with kubectl copy command to Windows AKS node
# 
# The script also install the azcopy on the current WSL session for copying uploaded
# traces from AKS windows node to Azure Storage to the local volume.
#
# This script is specifically written for Azure AKS environment, but it can be easily modified to run in other vendors' environments
# 
# Key concepts and tools used:
#    1. Interactions between WSL and Windows desktop
#    2. wget and unzip, tar

# Download the latest version of AzCopy for Windows 
wget https://aka.ms/downloadazcopy-v10-windows
unzip -o downloadazcopy-v10-windows 
cp ./azcopy_windows_amd64_*/azcopy.exe .

# Download and install AzCopy on WSL
wget https://aka.ms/downloadazcopy-v10-linux
tar -xvf downloadazcopy-v10-linux
sudo cp ./azcopy_linux_amd64_*/azcopy /usr/local/bin/
