############################################################
# Script to uninstall Docker Community Edition from Windows
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
        Uninstalls Docker Community Edition and cleans up associated components

    .DESCRIPTION
        Uninstalls Docker Community Edition, stops and removes the Docker service,
        removes Docker binaries, cleans up Docker data directory, and removes Docker networks.
        Optionally removes Windows features if they are no longer needed.

    .PARAMETER Force
        If specified, bypasses user confirmation prompts and proceeds with uninstallation automatically.
        
    .PARAMETER RemoveWindowsFeatures
        If specified, removes the Windows Container feature. Use with caution as this may affect other container runtimes.

    .PARAMETER KeepData
        If specified, preserves the Docker data directory and configuration files.

    .EXAMPLE
        .\uninstall-docker-ce.ps1
        
    .EXAMPLE
        .\uninstall-docker-ce.ps1 -Force
        
    .EXAMPLE
        .\uninstall-docker-ce.ps1 -Force -RemoveWindowsFeatures

#>
#Requires -Version 5.0

[CmdletBinding()]
param(
    [switch]
    $Force,

    [switch]
    $RemoveWindowsFeatures,

    [switch]
    $KeepData,

    [switch]
    $WhatIf
)

$global:DockerDataPath = "$($env:ProgramData)\docker"
$global:DockerServiceName = "docker"

function 
Test-Admin()
{
    # Skip admin check in WhatIf mode or on non-Windows platforms
    if ($WhatIf -or $env:OS -ne "Windows_NT")
    {
        Write-Output "Skipping admin check (WhatIf mode or non-Windows platform)"
        return $true
    }
    
    # Get the ID and security principal of the current user account
    $myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
    $myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
  
    # Get the security principal for the Administrator role
    $adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
  
    # Check to see if we are currently running "as Administrator"
    if ($myWindowsPrincipal.IsInRole($adminRole))
    {
        return $true
    }
    else
    {
        throw "You must run this script as administrator"   
    }
}

function
Get-UserConfirmation
{
    param(
        [string]$Message,
        [string]$Title = "Confirmation"
    )
    
    if ($WhatIf)
    {
        Write-Output "WHATIF: $Message"
        return $false
    }
    
    if ($Force)
    {
        Write-Output "$Message (proceeding automatically due to -Force flag)"
        return $true
    }
    
    $choice = $Host.UI.PromptForChoice($Title, $Message, @('&Yes', '&No'), 1)
    return ($choice -eq 0)
}

function
Stop-DockerService
{
    Write-Output "Checking Docker service status..."
    
    # Skip service operations on non-Windows platforms or in WhatIf mode
    if ($env:OS -ne "Windows_NT")
    {
        Write-Output "Skipping service operations (non-Windows platform)"
        return
    }
    
    $service = Get-Service -Name $global:DockerServiceName -ErrorAction SilentlyContinue
    
    if ($service -eq $null)
    {
        Write-Output "Docker service is not installed."
        return
    }
    
    if ($service.Status -eq 'Running')
    {
        $confirm = Get-UserConfirmation "Stop the Docker service?" "Stop Docker Service"
        if ($confirm)
        {
            if (-not $WhatIf)
            {
                Write-Output "Stopping Docker service..."
                Stop-Service -Name $global:DockerServiceName -Force
                Write-Output "Docker service stopped."
            }
            else
            {
                Write-Output "WHATIF: Would stop Docker service"
            }
        }
        else
        {
            Write-Warning "Docker service was not stopped. Some cleanup operations may fail."
        }
    }
    else
    {
        Write-Output "Docker service is already stopped."
    }
}

function
Remove-DockerService
{
    Write-Output "Checking if Docker service is registered..."
    
    # Skip service operations on non-Windows platforms
    if ($env:OS -ne "Windows_NT")
    {
        Write-Output "Skipping service operations (non-Windows platform)"
        return
    }
    
    $service = Get-Service -Name $global:DockerServiceName -ErrorAction SilentlyContinue
    
    if ($service -ne $null)
    {
        $confirm = Get-UserConfirmation "Remove the Docker service registration?" "Remove Docker Service"
        if ($confirm)
        {
            if (-not $WhatIf)
            {
                Write-Output "Removing Docker service registration..."
                # Use dockerd to unregister the service if available
                if (Test-Path "$env:windir\System32\dockerd.exe")
                {
                    & dockerd --unregister-service --service-name $global:DockerServiceName 2>$null
                }
                
                # Fallback to sc.exe if dockerd method fails
                $serviceCheck = Get-Service -Name $global:DockerServiceName -ErrorAction SilentlyContinue
                if ($serviceCheck -ne $null)
                {
                    sc.exe delete $global:DockerServiceName | Out-Null
                }
                
                Write-Output "Docker service registration removed."
            }
            else
            {
                Write-Output "WHATIF: Would remove Docker service registration"
            }
        }
        else
        {
            Write-Warning "Docker service registration was not removed."
        }
    }
    else
    {
        Write-Output "Docker service is not registered."
    }
}

function
Remove-DockerBinaries
{
    # Skip on non-Windows platforms
    if ($env:OS -ne "Windows_NT")
    {
        Write-Output "Skipping binary removal (non-Windows platform)"
        return
    }
    
    $dockerExe = "$env:windir\System32\docker.exe"
    $dockerdExe = "$env:windir\System32\dockerd.exe"
    
    $filesToRemove = @()
    if (Test-Path $dockerExe) { $filesToRemove += $dockerExe }
    if (Test-Path $dockerdExe) { $filesToRemove += $dockerdExe }
    
    if ($filesToRemove.Count -gt 0)
    {
        $fileList = $filesToRemove -join "`n  "
        $confirm = Get-UserConfirmation "Remove Docker binaries?`n  $fileList" "Remove Docker Binaries"
        if ($confirm)
        {
            if (-not $WhatIf)
            {
                Write-Output "Removing Docker binaries..."
                foreach ($file in $filesToRemove)
                {
                    try
                    {
                        Remove-Item -Path $file -Force
                        Write-Output "Removed: $file"
                    }
                    catch
                    {
                        Write-Warning "Failed to remove: $file - $($_.Exception.Message)"
                    }
                }
            }
            else
            {
                Write-Output "WHATIF: Would remove Docker binaries: $fileList"
            }
        }
        else
        {
            Write-Warning "Docker binaries were not removed."
        }
    }
    else
    {
        Write-Output "No Docker binaries found in System32."
    }
}

function
Remove-DockerNetworks
{
    Write-Output "Checking for Docker networks..."
    
    try
    {
        $networks = docker network ls --format "{{.Name}}" 2>$null
        if ($LASTEXITCODE -eq 0 -and $networks -ne $null)
        {
            $customNetworks = $networks | Where-Object { $_ -notin @('bridge', 'host', 'none', 'nat') }
            if ($customNetworks.Count -gt 0)
            {
                $networkList = $customNetworks -join "`n  "
                $confirm = Get-UserConfirmation "Remove Docker networks?`n  $networkList" "Remove Docker Networks"
                if ($confirm)
                {
                    Write-Output "Removing Docker networks..."
                    foreach ($network in $customNetworks)
                    {
                        try
                        {
                            docker network rm $network 2>$null
                            if ($LASTEXITCODE -eq 0)
                            {
                                Write-Output "Removed network: $network"
                            }
                        }
                        catch
                        {
                            Write-Warning "Failed to remove network: $network"
                        }
                    }
                }
                else
                {
                    Write-Warning "Docker networks were not removed."
                }
            }
            else
            {
                Write-Output "No custom Docker networks found."
            }
        }
        else
        {
            Write-Output "Cannot query Docker networks (Docker may not be running)."
        }
    }
    catch
    {
        Write-Output "Cannot query Docker networks: $($_.Exception.Message)"
    }
}

function
Remove-DockerData
{
    if ($KeepData)
    {
        Write-Output "Keeping Docker data directory due to -KeepData flag."
        return
    }
    
    if (Test-Path $global:DockerDataPath)
    {
        $confirm = Get-UserConfirmation "Remove Docker data directory and all container data?`n  $global:DockerDataPath`n  Warning: This will delete all containers, images, and volumes!" "Remove Docker Data"
        if ($confirm)
        {
            Write-Output "Removing Docker data directory..."
            try
            {
                Remove-Item -Path $global:DockerDataPath -Recurse -Force
                Write-Output "Docker data directory removed."
            }
            catch
            {
                Write-Warning "Failed to remove Docker data directory: $($_.Exception.Message)"
                Write-Warning "You may need to remove it manually after a reboot."
            }
        }
        else
        {
            Write-Warning "Docker data directory was not removed."
        }
    }
    else
    {
        Write-Output "Docker data directory does not exist."
    }
}

function
Remove-WindowsFeatures
{
    if (-not $RemoveWindowsFeatures)
    {
        Write-Output "Skipping Windows features removal. Use -RemoveWindowsFeatures to remove them."
        return
    }
    
    # Skip on non-Windows platforms
    if ($env:OS -ne "Windows_NT")
    {
        Write-Output "Skipping Windows features removal (non-Windows platform)"
        return
    }
    
    $confirm = Get-UserConfirmation "Remove Windows Container features? This may affect other container runtimes and require a restart." "Remove Windows Features"
    if (-not $confirm)
    {
        Write-Warning "Windows features were not removed."
        return
    }
    
    if ($WhatIf)
    {
        Write-Output "WHATIF: Would remove Windows Container features"
        return
    }
    
    Write-Output "Checking Windows Container features..."
    
    # Check and remove Containers feature
    if (Get-Command Get-WindowsFeature -ErrorAction SilentlyContinue)
    {
        # Windows Server
        $containerFeature = Get-WindowsFeature -Name Containers
        if ($containerFeature.InstallState -eq 'Installed')
        {
            Write-Output "Removing Containers feature..."
            Remove-WindowsFeature -Name Containers -Restart:$false
        }
        else
        {
            Write-Output "Containers feature is not installed."
        }
    }
    else
    {
        # Windows Client
        $containerFeature = Get-WindowsOptionalFeature -Online -FeatureName Containers
        if ($containerFeature.State -eq 'Enabled')
        {
            Write-Output "Removing Containers feature..."
            Disable-WindowsOptionalFeature -Online -FeatureName Containers -NoRestart
        }
        else
        {
            Write-Output "Containers feature is not enabled."
        }
    }
}

function
Uninstall-DockerCE
{
    Write-Output "Starting Docker CE uninstallation..."
    Write-Output "=================================================="
    
    # Verify admin privileges
    Test-Admin
    
    # Stop Docker service
    Stop-DockerService
    
    # Remove Docker networks (before stopping service completely)
    Remove-DockerNetworks
    
    # Remove Docker service registration
    Remove-DockerService
    
    # Remove Docker binaries
    Remove-DockerBinaries
    
    # Remove Docker data directory
    Remove-DockerData
    
    # Remove Windows features if requested
    Remove-WindowsFeatures
    
    Write-Output "=================================================="
    Write-Output "Docker CE uninstallation completed."
    
    if ($RemoveWindowsFeatures -and -not $Force)
    {
        Write-Output "Note: A restart may be required to complete Windows feature removal."
    }
}

try
{
    Uninstall-DockerCE
}
catch 
{
    Write-Error "Uninstallation failed: $($_.Exception.Message)"
    exit 1
}