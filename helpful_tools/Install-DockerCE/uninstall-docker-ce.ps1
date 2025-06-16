############################################################
# Script to uninstall the community edition of docker from Windows
############################################################

<#
    .NOTES
        Copyright (c) Microsoft Corporation.  All rights reserved.

        Use of this sample source code is subject to the terms of the Microsoft
        license agreement under which you licensed this sample source code. If
        you did not accept the terms of the license agreement, you are not
        authorized to use this sample source code. For the terms of the license,
        please see the license agreement between you and Microsoft or, if applicable,
        see the LICENSE.RTF on your install media or the root of your tools installation.
        THE SAMPLE SOURCE CODE IS PROVIDED "AS IS", WITH NO WARRANTIES.

    .SYNOPSIS
        Uninstalls Docker Community Edition and removes related components

    .DESCRIPTION
        Uninstalls Docker Community Edition from Windows, including the service,
        binaries, configuration, and optionally images and networks.

    .PARAMETER RemoveImages
        If specified, removes all Docker images before uninstalling

    .PARAMETER RemoveNetworks
        If specified, removes all custom Docker networks before uninstalling

    .PARAMETER KeepData
        If specified, preserves Docker data directory (images, containers, volumes)

    .PARAMETER Force
        If specified, skips confirmation prompts and forces removal

    .PARAMETER RemoveWindowsFeatures
        If specified, removes Windows Container and Hyper-V features (use with caution)

    .EXAMPLE
        .\uninstall-docker-ce.ps1

    .EXAMPLE
        .\uninstall-docker-ce.ps1 -RemoveImages -RemoveNetworks

    .EXAMPLE
        .\uninstall-docker-ce.ps1 -Force -RemoveImages

#>
#Requires -Version 5.0

[CmdletBinding()]
param(
    [switch]
    $RemoveImages,

    [switch]
    $RemoveNetworks,

    [switch]
    $KeepData,

    [switch]
    $Force,

    [switch]
    $RemoveWindowsFeatures
)

$global:DockerDataPath = "$($env:ProgramData)\docker"
$global:DockerServiceName = "docker"
$global:AdminPrivileges = $false

function 
Test-Admin()
{
    # Get the ID and security principal of the current user account
    $myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
    $myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
  
    # Get the security principal for the Administrator role
    $adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
  
    # Check to see if we are currently running "as Administrator"
    if ($myWindowsPrincipal.IsInRole($adminRole))
    {
        $global:AdminPrivileges = $true
        return
    }
    else
    {
        #
        # We are not running "as Administrator"
        # Exit from the current, unelevated, process
        #
        throw "You must run this script as administrator"   
    }
}

function 
Test-Docker()
{
    $service = Get-Service -Name $global:DockerServiceName -ErrorAction SilentlyContinue
    return ($service -ne $null)
}

function
Stop-Docker()
{
    if (Test-Docker)
    {
        $service = Get-Service -Name $global:DockerServiceName -ErrorAction SilentlyContinue
        if ($service.Status -eq 'Running')
        {
            Write-Output "Stopping Docker service..."
            try
            {
                Stop-Service -Name $global:DockerServiceName -Force -ErrorAction Stop
                Write-Output "Docker service stopped successfully."
            }
            catch
            {
                Write-Warning "Failed to stop Docker service: $_"
            }
        }
        elseif ($service.Status -eq 'Stopped')
        {
            Write-Output "Docker service is already stopped."
        }
        else
        {
            Write-Output "Docker service is in '$($service.Status)' state."
        }
    }
    else
    {
        Write-Output "Docker service is not installed."
    }
}

function
Remove-DockerService()
{
    if (Test-Docker)
    {
        Write-Output "Removing Docker service..."
        try
        {
            # Stop the service first
            Stop-Docker
            
            # Remove the service using sc.exe for more reliable deletion
            $result = & sc.exe delete $global:DockerServiceName 2>&1
            if ($LASTEXITCODE -eq 0)
            {
                Write-Output "Docker service removed successfully."
            }
            else
            {
                Write-Warning "Failed to remove Docker service. Exit code: $LASTEXITCODE. Output: $result"
            }
        }
        catch
        {
            Write-Warning "Failed to remove Docker service: $_"
        }
    }
    else
    {
        Write-Output "Docker service is not installed."
    }
}

function
Remove-DockerBinaries()
{
    Write-Output "Removing Docker binaries..."
    
    $dockerExe = Join-Path $env:windir "System32\docker.exe"
    $dockerdExe = Join-Path $env:windir "System32\dockerd.exe"
    
    if (Test-Path $dockerExe)
    {
        try
        {
            Remove-Item $dockerExe -Force
            Write-Output "Removed docker.exe from System32."
        }
        catch
        {
            Write-Warning "Failed to remove docker.exe: $_"
        }
    }
    else
    {
        Write-Output "docker.exe not found in System32."
    }
    
    if (Test-Path $dockerdExe)
    {
        try
        {
            Remove-Item $dockerdExe -Force
            Write-Output "Removed dockerd.exe from System32."
        }
        catch
        {
            Write-Warning "Failed to remove dockerd.exe: $_"
        }
    }
    else
    {
        Write-Output "dockerd.exe not found in System32."
    }
}

function
Remove-DockerContainers()
{
    Write-Output "Checking for existing Docker containers..."
    try
    {
        $containers = docker ps -aq 2>$null
        if ($containers)
        {
            $containerCount = ($containers | Measure-Object).Count
            $runningContainers = docker ps -q 2>$null
            $runningCount = if ($runningContainers) { ($runningContainers | Measure-Object).Count } else { 0 }
            
            Write-Output "Found $containerCount Docker container(s) ($runningCount running)."
            
            if (-not $Force)
            {
                $message = "Do you want to stop and remove all $containerCount Docker container(s)"
                if ($runningCount -gt 0) { $message += " (including $runningCount running)" }
                $message += "? (y/N)"
                
                $response = Read-Host $message
                if ($response -ne "y" -and $response -ne "Y")
                {
                    Write-Output "User chose not to remove containers. Aborting uninstall process."
                    exit 0
                }
            }
            
            Write-Output "Stopping and removing all Docker containers..."
            docker stop $containers 2>$null | Out-Null
            docker rm -f $containers 2>$null
            Write-Output "Docker containers removed."
        }
        else
        {
            Write-Output "No Docker containers found."
        }
    }
    catch
    {
        Write-Warning "Failed to remove Docker containers: $_"
    }
}

function
Remove-DockerVolumes()
{
    Write-Output "Checking for existing Docker volumes..."
    try
    {
        $volumes = docker volume ls -q 2>$null
        if ($volumes)
        {
            $volumeCount = ($volumes | Measure-Object).Count
            Write-Output "Found $volumeCount Docker volume(s)."
            
            if (-not $Force)
            {
                $response = Read-Host "Do you want to remove all $volumeCount Docker volume(s)? (y/N)"
                if ($response -ne "y" -and $response -ne "Y")
                {
                    Write-Output "Skipping Docker volumes removal."
                    return
                }
            }
            
            Write-Output "Removing all Docker volumes..."
            docker volume rm -f $volumes 2>$null
            Write-Output "Docker volumes removed."
        }
        else
        {
            Write-Output "No Docker volumes found."
        }
    }
    catch
    {
        Write-Warning "Failed to remove Docker volumes: $_"
    }
}

function
Remove-DockerImages()
{
    if ($RemoveImages)
    {
        Write-Output "Checking for existing Docker images..."
        try
        {
            $images = docker images -q 2>$null
            if ($images)
            {
                $imageCount = ($images | Measure-Object).Count
                Write-Output "Found $imageCount Docker image(s)."
                
                if (-not $Force)
                {
                    $response = Read-Host "Do you want to remove all $imageCount Docker image(s)? (y/N)"
                    if ($response -ne "y" -and $response -ne "Y")
                    {
                        Write-Output "Skipping Docker images removal."
                        return
                    }
                }
                
                Write-Output "Removing all Docker images..."
                docker rmi -f $images 2>$null
                Write-Output "Docker images removed."
            }
            else
            {
                Write-Output "No Docker images found."
            }
        }
        catch
        {
            Write-Warning "Failed to remove Docker images: $_"
        }
    }
}

function
Remove-DockerNetworks()
{
    if ($RemoveNetworks)
    {
        Write-Output "Removing custom Docker networks..."
        try
        {
            $networks = docker network ls --format "{{.Name}}" 2>$null
            if ($networks)
            {
                foreach ($network in $networks)
                {
                    # Skip default networks
                    if ($network -ne "bridge" -and $network -ne "host" -and $network -ne "none" -and $network -ne "nat")
                    {
                        Write-Output "Removing network: $network"
                        docker network rm $network 2>$null
                    }
                }
                Write-Output "Custom Docker networks removed."
            }
            else
            {
                Write-Output "No Docker networks found."
            }
        }
        catch
        {
            Write-Warning "Failed to remove Docker networks: $_"
        }
    }
}

function
Stop-WindowsContainerServices()
{
    # Stop additional Windows Container services that might be locking files
    $services = @("cexecsvc", "vmcompute", "vmicguestinterface", "vmicheartbeat", "vmickvpexchange", "vmicrdv", "vmicshutdown", "vmictimesync", "vmicvmsession", "vmicvss")
    
    Write-Output "Stopping additional Windows Container services..."
    foreach ($serviceName in $services)
    {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service -and $service.Status -eq 'Running')
        {
            try
            {
                Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
            }
            catch
            {
                # Ignore errors for services we can't stop
            }
        }
    }
}

function
Test-LingeringContainers()
{
    Write-Output "Checking for lingering containers and compute processes..."
    
    # Check using hcsdiag list if available
    try
    {
        $hcsdiagOutput = & hcsdiag.exe list 2>$null
        if ($hcsdiagOutput)
        {
            $containerMatches = $hcsdiagOutput | Select-String -Pattern "container" -SimpleMatch
            if ($containerMatches)
            {
                Write-Warning "Found lingering containers via hcsdiag:"
                $containerMatches | ForEach-Object { Write-Warning "  $_" }
                
                # Attempt to clean up these containers
                Write-Output "Attempting to terminate lingering containers..."
                $containerMatches | ForEach-Object {
                    $line = $_.Line
                    # Extract container ID if possible and attempt cleanup
                    if ($line -match '\{([^}]+)\}')
                    {
                        $containerId = $Matches[1]
                        try
                        {
                            & hcsdiag.exe kill $containerId 2>$null
                            Write-Output "Terminated container: $containerId"
                        }
                        catch
                        {
                            Write-Warning "Failed to terminate container $containerId : $_"
                        }
                    }
                }
            }
        }
    }
    catch
    {
        Write-Output "hcsdiag.exe not available or failed: $_"
    }
    
    # Check using Get-ComputeProcess if available
    try
    {
        if (Get-Command Get-ComputeProcess -ErrorAction SilentlyContinue)
        {
            $computeProcesses = Get-ComputeProcess -ErrorAction SilentlyContinue
            if ($computeProcesses)
            {
                $containerProcesses = $computeProcesses | Where-Object { $_.Type -like "*container*" }
                if ($containerProcesses)
                {
                    Write-Warning "Found lingering compute processes:"
                    $containerProcesses | ForEach-Object { 
                        Write-Warning "  Process: $($_.Id) Type: $($_.Type)" 
                        
                        # Attempt to stop the process
                        try
                        {
                            $_ | Stop-ComputeProcess -Force -ErrorAction SilentlyContinue
                            Write-Output "Stopped compute process: $($_.Id)"
                        }
                        catch
                        {
                            Write-Warning "Failed to stop compute process $($_.Id): $_"
                        }
                    }
                }
            }
        }
    }
    catch
    {
        Write-Output "Get-ComputeProcess not available or failed: $_"
    }
    
    # Wait a moment for cleanup to complete
    Start-Sleep -Seconds 3
}

function
Remove-DockerData()
{
    if (-not $KeepData)
    {
        if (Test-Path $global:DockerDataPath)
        {
            Write-Output "Removing Docker data directory..."
            
            # Stop additional services that might be locking container files
            Stop-WindowsContainerServices
            
            # Wait a moment for services to fully stop
            Start-Sleep -Seconds 2
            
            # Check for selective removal based on user preferences
            $removeWindowsFilter = -not ($RemoveImages -eq $false -and $RemoveNetworks -eq $false)
            $removeVolumes = $true  # Always remove volumes unless KeepData is specified
            
            # If user wants to keep images or networks, preserve windowsfilter
            if (-not $RemoveImages -or -not $RemoveNetworks)
            {
                $removeWindowsFilter = $false
                Write-Output "Preserving windowsfilter directory due to -RemoveImages=$RemoveImages or -RemoveNetworks=$RemoveNetworks settings"
            }
            
            try
            {
                # Check for lingering containers before attempting windowsfilter removal
                if ($removeWindowsFilter)
                {
                    Write-Output "Checking for lingering containers before windowsfilter removal..."
                    Test-LingeringContainers
                }
                
                # Special handling for windowsfilter directory which is often problematic
                $windowsFilterPath = Join-Path $global:DockerDataPath "windowsfilter"
                if ($removeWindowsFilter -and (Test-Path $windowsFilterPath))
                {
                    Write-Output "Removing windowsfilter directory with HCS layer destruction..."
                    
                    # Use HCS (Host Compute Service) API to properly destroy container layers
                    # This is more reliable than standard file deletion for windowsfilter
                    try
                    {
                        # Get all layer directories in windowsfilter
                        $layerDirs = Get-ChildItem -Path $windowsFilterPath -Directory -ErrorAction SilentlyContinue
                        
                        if ($layerDirs)
                        {
                            Write-Output "Destroying $($layerDirs.Count) container layer(s) using HCS API..."
                            
                            # Load the HCS API and destroy each layer
                            $job = Start-Job -ScriptBlock {
                                param($layers)
                                
                                # Add the ComputeStorage.dll type definition
                                try
                                {
                                    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class Hcs 
{
    [DllImport("ComputeStorage.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    public static extern int HcsDestroyLayer(string layerPath);
}
"@
                                }
                                catch
                                {
                                    # Type may already be defined, continue
                                }
                                
                                $results = @()
                                foreach ($layer in $layers)
                                {
                                    try
                                    {
                                        $result = [Hcs]::HcsDestroyLayer($layer.FullName)
                                        $results += [PSCustomObject]@{
                                            Layer = $layer.Name
                                            Path = $layer.FullName
                                            Result = $result
                                            Success = ($result -eq 0)
                                        }
                                    }
                                    catch
                                    {
                                        $results += [PSCustomObject]@{
                                            Layer = $layer.Name
                                            Path = $layer.FullName
                                            Result = -1
                                            Success = $false
                                            Error = $_.Exception.Message
                                        }
                                    }
                                }
                                return $results
                            } -ArgumentList @(,$layerDirs)
                            
                            # Wait for the job to complete with a reasonable timeout
                            $timeout = 120 # 2 minutes
                            if ($job | Wait-Job -Timeout $timeout)
                            {
                                $results = $job | Receive-Job
                                $job | Remove-Job
                                
                                $successCount = ($results | Where-Object { $_.Success }).Count
                                $failCount = ($results | Where-Object { -not $_.Success }).Count
                                
                                Write-Output "HCS layer destruction completed: $successCount successful, $failCount failed"
                                
                                if ($failCount -gt 0)
                                {
                                    Write-Warning "Some layers could not be destroyed using HCS API. Attempting standard removal..."
                                }
                            }
                            else
                            {
                                Write-Warning "HCS layer destruction timed out after $timeout seconds. Stopping job and continuing with standard removal..."
                                $job | Stop-Job
                                $job | Remove-Job
                            }
                        }
                    }
                    catch
                    {
                        Write-Warning "HCS layer destruction failed: $_. Continuing with standard removal methods..."
                    }
                    
                    # After HCS destruction, try standard removal if directory still exists
                    if (Test-Path $windowsFilterPath)
                    {
                        Write-Output "Attempting standard removal of remaining windowsfilter contents..."
                        
                        # Try to remove using rd command which can handle some locked files
                        & cmd.exe /c "rd /s /q `"$windowsFilterPath`"" 2>$null | Out-Null
                        
                        # If rd fails, try robocopy purge as fallback
                        if (Test-Path $windowsFilterPath)
                        {
                            $tempEmptyDir = Join-Path $env:TEMP "EmptyDir_$(Get-Random)"
                            try
                            {
                                New-Item -ItemType Directory -Path $tempEmptyDir -Force | Out-Null
                                & robocopy.exe $tempEmptyDir $windowsFilterPath /MIR /R:1 /W:1 /NP /NFL /NDL /NJH /NJS 2>$null | Out-Null
                                Remove-Item $tempEmptyDir -Force -ErrorAction SilentlyContinue
                            }
                            catch
                            {
                                Remove-Item $tempEmptyDir -Force -ErrorAction SilentlyContinue
                            }
                        }
                    }
                }
                
                # Now perform selective removal based on user preferences
                Write-Output "Performing selective cleanup of Docker data directory..."
                
                # Take ownership of the Docker data directory and its contents for directories we want to remove
                Write-Output "Taking ownership of Docker data directory..."
                
                # Use Start-Process with timeout to handle hanging takeown operation
                $takeownProcess = Start-Process -FilePath "takeown.exe" -ArgumentList "/f", $global:DockerDataPath, "/r", "/d", "y" -WindowStyle Hidden -PassThru
                
                # Wait for up to 3 minutes for takeown to complete
                $timeoutMinutes = 3
                $timeoutMs = $timeoutMinutes * 60 * 1000
                
                if (-not $takeownProcess.WaitForExit($timeoutMs))
                {
                    # Process is still running after timeout, kill it
                    Write-Warning "Taking ownership is taking longer than $timeoutMinutes minutes. Terminating process..."
                    try
                    {
                        $takeownProcess.Kill()
                        $takeownProcess.WaitForExit(5000) # Wait up to 5 seconds for kill to complete
                    }
                    catch
                    {
                        Write-Warning "Failed to terminate takeown process: $_"
                    }
                    Write-Warning "Taking ownership of Docker data directory timed out after $timeoutMinutes minutes."
                    # Continue with removal attempt even if takeown timed out
                }
                
                # Grant full control to the current user
                & icacls.exe $global:DockerDataPath /grant "$env:USERNAME`:F" /t /c 2>$null | Out-Null
                
                # Define directories to remove based on user preferences
                $directoriesToRemove = @()
                
                # Always remove containers directory
                $containersPath = Join-Path $global:DockerDataPath "containers"
                if (Test-Path $containersPath)
                {
                    $directoriesToRemove += $containersPath
                }
                
                # Remove image directory only if not preserving images
                if ($RemoveImages)
                {
                    $imagePath = Join-Path $global:DockerDataPath "image"
                    if (Test-Path $imagePath)
                    {
                        $directoriesToRemove += $imagePath
                    }
                }
                
                # Remove network directory only if not preserving networks  
                if ($RemoveNetworks)
                {
                    $networkPath = Join-Path $global:DockerDataPath "network"
                    if (Test-Path $networkPath)
                    {
                        $directoriesToRemove += $networkPath
                    }
                }
                
                # Remove volumes directory (always removed unless KeepData is specified)
                # Note: KeepData is already checked at the beginning of this function
                $volumesPath = Join-Path $global:DockerDataPath "volumes"
                if (Test-Path $volumesPath)
                {
                    $directoriesToRemove += $volumesPath
                }
                
                # Remove configuration files
                $configFiles = @("daemon.json", "key.json")
                foreach ($configFile in $configFiles)
                {
                    $configPath = Join-Path $global:DockerDataPath $configFile
                    if (Test-Path $configPath)
                    {
                        try
                        {
                            Remove-Item $configPath -Force -ErrorAction Stop
                            Write-Output "Removed Docker configuration file: $configFile"
                        }
                        catch
                        {
                            Write-Warning "Failed to remove configuration file $configFile : $_"
                        }
                    }
                }
                
                # Remove selected directories
                foreach ($dirPath in $directoriesToRemove)
                {
                    $dirName = Split-Path $dirPath -Leaf
                    Write-Output "Removing Docker $dirName directory..."
                    
                    try
                    {
                        Remove-Item $dirPath -Recurse -Force -ErrorAction Stop
                        Write-Output "Successfully removed $dirName directory"
                    }
                    catch
                    {
                        Write-Warning "Failed to remove $dirName directory using Remove-Item: $_"
                        
                        # Try rd command as fallback
                        try
                        {
                            & cmd.exe /c "rd /s /q `"$dirPath`""
                            if (-not (Test-Path $dirPath))
                            {
                                Write-Output "Successfully removed $dirName directory using rd command"
                            }
                            else
                            {
                                Write-Warning "rd command failed to remove $dirName directory"
                            }
                        }
                        catch
                        {
                            Write-Warning "rd command failed for $dirName directory: $_"
                        }
                    }
                }
                
                # Check if Docker data directory is now empty (except for preserved directories)
                $remainingItems = Get-ChildItem -Path $global:DockerDataPath -ErrorAction SilentlyContinue
                if (-not $remainingItems)
                {
                    # Directory is empty, remove it completely
                    try
                    {
                        Remove-Item $global:DockerDataPath -Force -ErrorAction Stop
                        Write-Output "Docker data directory completely removed"
                    }
                    catch
                    {
                        Write-Warning "Failed to remove empty Docker data directory: $_"
                    }
                }
                else
                {
                    Write-Output "Docker data directory preserved with remaining components:"
                    $remainingItems | ForEach-Object { Write-Output "  - $($_.Name)" }
                }
            }
            catch
            {
                Write-Warning "Failed to remove Docker data directory: $_"
                Write-Warning "You may need to manually remove $global:DockerDataPath"
            }
        }
        else
        {
            Write-Output "Docker data directory not found."
        }
        
        # Also remove downloaded Docker files from user profile
        $dockerDownloads = "$env:UserProfile\DockerDownloads"
        if (Test-Path $dockerDownloads)
        {
            Write-Output "Removing Docker download files..."
            try
            {
                Remove-Item $dockerDownloads -Recurse -Force
                Write-Output "Docker download files removed."
            }
            catch
            {
                Write-Warning "Failed to remove Docker download files: $_"
            }
        }
    }
    else
    {
        Write-Output "Preserving Docker data directory as requested."
    }
}

function
Remove-DockerRegistryKeys()
{
    Write-Output "Removing Docker registry keys..."
    
    $registryPaths = @(
        "HKLM:\SYSTEM\CurrentControlSet\Services\docker",
        "HKLM:\SYSTEM\ControlSet002\Services\docker"
    )
    
    foreach ($regPath in $registryPaths)
    {
        try
        {
            if (Test-Path $regPath)
            {
                Write-Output "Removing registry key: $regPath"
                Remove-Item $regPath -Recurse -Force
                Write-Output "Registry key removed: $regPath"
            }
            # Registry key not found - silently continue
        }
        catch
        {
            Write-Warning "Failed to remove registry key $regPath`: $_"
        }
    }
}

function
Remove-WindowsFeatures()
{
    if ($RemoveWindowsFeatures)
    {
        Write-Output "WARNING: Removing Windows features may affect other software on this system."
        if (-not $Force)
        {
            $response = Read-Host "Are you sure you want to remove Windows Container and Hyper-V features? (y/N)"
            if ($response -ne "y" -and $response -ne "Y")
            {
                Write-Output "Skipping Windows features removal."
                return
            }
        }
        
        Write-Output "Removing Windows Container feature..."
        try
        {
            if (Get-Command Get-WindowsFeature -ErrorAction SilentlyContinue)
            {
                # Server editions
                Remove-WindowsFeature -Name Containers
            }
            else
            {
                # Client editions
                Disable-WindowsOptionalFeature -Online -FeatureName Containers
            }
            Write-Output "Windows Container feature removed."
        }
        catch
        {
            Write-Warning "Failed to remove Windows Container feature: $_"
        }
        
        Write-Output "Removing Hyper-V feature..."
        try
        {
            if (Get-Command Get-WindowsFeature -ErrorAction SilentlyContinue)
            {
                # Server editions
                Remove-WindowsFeature -Name Hyper-V
            }
            else
            {
                # Client editions
                Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
            }
            Write-Output "Hyper-V feature removed."
        }
        catch
        {
            Write-Warning "Failed to remove Hyper-V feature: $_"
        }
        
        Write-Output "Windows features removal completed. A restart may be required."
    }
}

function
Remove-DockerCE()
{
    Write-Output "Starting Docker CE uninstallation..."
    
    Test-Admin
    
    # Show what will be removed
    Write-Output "The following actions will be performed:"
    Write-Output "- Stop and remove all Docker containers"
    Write-Output "- Stop and remove Docker service"
    Write-Output "- Remove Docker binaries from System32"
    
    if ($RemoveImages)
    {
        Write-Output "- Remove all Docker images"
    }
    
    if ($RemoveNetworks)
    {
        Write-Output "- Remove custom Docker networks"
    }
    
    if (-not $KeepData)
    {
        Write-Output "- Remove Docker data directory"
    }
    
    if ($RemoveWindowsFeatures)
    {
        Write-Output "- Remove Windows Container and Hyper-V features"
    }
    
    # Confirm before proceeding
    if (-not $Force)
    {
        $response = Read-Host "`nDo you want to continue? (y/N)"
        if ($response -ne "y" -and $response -ne "Y")
        {
            Write-Output "Uninstallation cancelled."
            return
        }
    }
    
    # Remove containers, volumes, images and networks first (while Docker is still running or available)
    # We'll try to clean these up even if the service is stopped, as docker CLI might still work
    if (Test-Docker)
    {
        try 
        {
            # Test if docker CLI is available and responsive
            $null = docker version 2>$null
            if ($LASTEXITCODE -eq 0)
            {
                Remove-DockerContainers
                Remove-DockerVolumes
                Remove-DockerImages
                Remove-DockerNetworks
            }
            else
            {
                Write-Output "Docker CLI is not responsive. Skipping container/volume/image/network cleanup."
            }
        }
        catch
        {
            Write-Output "Docker CLI is not available. Skipping container/volume/image/network cleanup."
        }
    }
    else
    {
        Write-Output "Docker service not found. Skipping container/volume/image/network cleanup."
    }
    
    # Stop and remove Docker service
    Remove-DockerService
    
    # Remove Docker registry keys
    Remove-DockerRegistryKeys
    
    # Remove binaries
    Remove-DockerBinaries
    
    # Remove data directory
    Remove-DockerData
    
    # Remove Windows features if requested
    Remove-WindowsFeatures
    
    Write-Output "Docker CE uninstallation completed."
    
    if ($RemoveWindowsFeatures)
    {
        Write-Output "A restart may be required to complete Windows features removal."
    }
}

try
{
    Remove-DockerCE
}
catch 
{
    Write-Error $_
}