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
        binaries, configuration, images, networks, containers, and volumes by default.

    .PARAMETER KeepData
        If specified, preserves Docker data directory (images, containers, volumes)

    .PARAMETER KeepImages
        If specified, preserves images (and, therefore, Docker data directory)

    .PARAMETER KeepVolumes
        If specified, preserves volumes (and, therefore, Docker data directory)

    .PARAMETER KeepNetworks
        If specified, preserves custom networks (and, therefore, Docker data directory)

    .PARAMETER Force
        If specified, skips confirmation prompts and forces removal

    .EXAMPLE
        .\uninstall-docker-ce.ps1

    .EXAMPLE
        .\uninstall-docker-ce.ps1 -Force

    .EXAMPLE
        .\uninstall-docker-ce.ps1 -KeepImages

    .EXAMPLE
        .\uninstall-docker-ce.ps1 -KeepVolumes -KeepNetworks

#>
#Requires -Version 5.0

[CmdletBinding()]
param(
    [switch]
    $KeepData,

    [switch]
    $KeepImages,

    [switch]
    $KeepVolumes,

    [switch]
    $KeepNetworks,

    [switch]
    $Force
)

$global:DockerDataPath = "$($env:ProgramData)\docker"
$global:DockerServiceName = "docker"
$global:AdminPrivileges = $false

function Test-Admin()
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

function Test-Docker()
{
    $service = Get-Service -Name $global:DockerServiceName -ErrorAction SilentlyContinue
    return ($service -ne $null)
}

function Stop-Docker()
{
    if (Test-Docker)
    {
        $service = Get-Service -Name $global:DockerServiceName -ErrorAction SilentlyContinue
        if ($service.Status -eq 'Running')
        {
            try
            {
                Stop-Service -Name $global:DockerServiceName -Force -ErrorAction Stop
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
}

function Remove-DockerService()
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

function Remove-DockerBinaries()
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

function Remove-DockerContainers()
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

function Remove-DockerVolumes()
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

function Remove-DockerImages()
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

function Remove-DockerNetworks()
{
    Write-Output "Checking for existing Docker networks..."
    try
    {
        $networks = docker network ls --format "{{.Name}}" 2>$null
        if ($networks)
        {
            # Filter out default networks
            $customNetworks = @()
            foreach ($network in $networks)
            {
                if ($network -ne "bridge" -and $network -ne "host" -and $network -ne "none" -and $network -ne "nat")
                {
                    $customNetworks += $network
                }
            }
            
            if ($customNetworks.Count -gt 0)
            {
                Write-Output "Found $($customNetworks.Count) custom Docker network(s)."
                
                if (-not $Force)
                {
                    $response = Read-Host "Do you want to remove all $($customNetworks.Count) custom Docker network(s)? (y/N)"
                    if ($response -ne "y" -and $response -ne "Y")
                    {
                        Write-Output "Skipping Docker networks removal."
                        return
                    }
                }
                
                Write-Output "Removing custom Docker networks..."
                foreach ($network in $customNetworks)
                {
                    Write-Output "Removing network: $network"
                    docker network rm $network 2>$null
                }
                Write-Output "Custom Docker networks removed."
            }
            else
            {
                Write-Output "No custom Docker networks found."
            }
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

function Stop-WindowsContainerServices()
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

function Test-LingeringContainers()
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

function Remove-DockerData()
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
            
            # Since we always remove images and networks, always remove windowsfilter
            $removeWindowsFilter = $true
            $removeVolumes = $true  # Always remove volumes unless KeepData is specified
            
            try
            {
                # Check for lingering containers before attempting windowsfilter removal
                Test-LingeringContainers
                
                # Special handling for windowsfilter directory which is often problematic
                $windowsFilterPath = Join-Path $global:DockerDataPath "windowsfilter"
                if ($removeWindowsFilter -and (Test-Path $windowsFilterPath))
                {                    
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
                            if (Wait-Job $job -Timeout $timeout)
                            {
                                $results = Receive-Job $job
                                Remove-Job $job
                                
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
                
                # After windowsfilter special handling, remove everything else from the docker folder
                # in the default case (user did not ask to preserve data)
                Remove-Item $global:DockerDataPath -Recurse -Force
                Write-Output "Docker data directory removed."
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
}

function Remove-DockerRegistryKeys()
{
    Write-Output "Removing Docker registry keys..."
    
    $registryPaths = @(
        "HKLM:\SYSTEM\CurrentControlSet\Services\docker",
        "HKLM:\SYSTEM\ControlSet002\Services\docker",
        "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application\docker"
    )
    
    foreach ($regPath in $registryPaths)
    {
        try
        {
            if (Test-Path $regPath)
            {
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

function Remove-DockerCE()
{
    Write-Output "Starting Docker CE uninstallation..."
    
    Test-Admin
    
    # Show what will be removed
    Write-Output "The following actions will be performed:"
    Write-Output "- Stop and remove all Docker containers"
    Write-Output "- Stop and remove Docker service"
    Write-Output "- Remove Docker binaries"

    if (-not $KeepImages) 
    {
        Write-Output "- Remove all Docker images"
    }

    if (-not $KeepVolumes)
    {
        Write-Output "- Remove all Docker volumes"
    }
    
    if (-not $KeepNetworks)
    {
        Write-Output "- Remove custom Docker networks"
    }
    
    if (-not $KeepImages -and -not $KeepVolumes -and -not $KeepNetworks)
    {
        Write-Output "- Remove Docker data directory"
    }
    
    
    # Confirm before proceeding
    if (-not $Force)
    {
        $response = Read-Host "`nDo you want to continue? (y/N)"
        if ($response -ne "y" -and $response -ne "Y")
        {
            Write-Output "`nUninstallation cancelled."
            return
        }
    }
    
    # Use Docker to remove containers, volumes, images and networks first
    if (Test-Docker)
    {
        try 
        {
            # Test if docker CLI is available and responsive
            $null = docker version 2>$null
            if ($LASTEXITCODE -eq 0)
            {
                # Always gracefully shutdown all containers
                Remove-DockerContainers

                # Only remove images, volumes, and networks if requested
                if (-not $KeepImages)
                {
                    Remove-DockerImages
                }

                if (-not $KeepVolumes)
                {
                    Remove-DockerVolumes
                }
                
                if (-not $KeepNetworks)
                {
                    Remove-DockerNetworks
                }
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
    if (-not $KeepImages -and -not $KeepVolumes -and -not $KeepNetworks)
    {
        Remove-DockerData
    }
    
    Write-Output "`nDocker CE uninstallation completed.`n"
}

try
{
    Remove-DockerCE
}
catch 
{
    Write-Error $_
}