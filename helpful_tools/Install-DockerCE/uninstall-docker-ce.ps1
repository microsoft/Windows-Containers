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
            
            # Remove the service
            $service = Get-WmiObject -Class Win32_Service -Filter "Name='$global:DockerServiceName'"
            if ($service)
            {
                $service.delete()
                Write-Output "Docker service removed successfully."
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
Remove-DockerImages()
{
    if ($RemoveImages)
    {
        Write-Output "Removing all Docker images..."
        try
        {
            $images = docker images -q 2>$null
            if ($images)
            {
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
Remove-DockerData()
{
    if (-not $KeepData)
    {
        if (Test-Path $global:DockerDataPath)
        {
            Write-Output "Removing Docker data directory..."
            try
            {
                Remove-Item $global:DockerDataPath -Recurse -Force
                Write-Output "Docker data directory removed."
            }
            catch
            {
                Write-Warning "Failed to remove Docker data directory: $_"
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
    
    # Remove images and networks first (while Docker is still running)
    if (Test-Docker)
    {
        Remove-DockerImages
        Remove-DockerNetworks
    }
    
    # Stop and remove Docker service
    Remove-DockerService
    
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