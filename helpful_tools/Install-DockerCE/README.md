## install-docker-ce.ps1

#### NAME
    install-docker-ce.ps1
    
#### SYNOPSIS
    Installs the prerequisites for running Windows containers with Docker CE
    
#### SYNTAX
    install-docker-ce.ps1 [-DockerPath <String>] [-DockerDPath <String>] [-DockerVersion <String>] [-ContainerBaseImage <String>] [-ExternalNetAdapter <String>] 
    [-Force] [-HyperV] [-SkipDefaultHost] [-NATSubnet <String>] [-NoRestart] [-PSDirect] [-Staging] 
    [-UseDHCP] [-WimPath <String>] [-TarPath] [<CommonParameters>]
    
    
#### DESCRIPTION
    Installs the prerequisites for creating Windows containers with Docker Community Edition
    

#### PARAMETERS
    -DockerPath [<String>]
        Path to Docker.exe, can be local or URI.
        
        Required?                    True
        Position?                    named
        Default value                default
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -DockerDPath [<String>]
        Path to DockerD.exe, can be local or URI.
        
        Required?                    True
        Position?                    named
        Default value                default
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -DockerVersion [<String>]
        The version of docker to use.
        
        Required?                    True
        Position?                    named
        Default value                latest
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -ExternalNetAdapter [<String>]
        Specify a specific network adapter to bind to a DHCP switch.
        
        Required?                    false
        Position?                    named
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -SkipDefaultHost [<SwitchParameter>]
        Prevents setting localhost as the default network configuration.

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -Force [<SwitchParameter>]
        If a restart is required, forces an immediate restart.
        
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -HyperV [<SwitchParameter>]
        If passed, prepare the machine for Hyper-V containers
        
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -NATSubnet [<String>]
        Use to override the default Docker NAT Subnet when in NAT mode.

        Required?                    false
        Position?                    named
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -NoRestart [<SwitchParameter>]
        If a restart is required the script will terminate and will not reboot the machine
        
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -ContainerBaseImage [<String>]
        Use this to specify the URI of the container base image you wish to pre-pull
        
        Required?                    false
        Position?                    named
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -Staging [<SwitchParameter>]
        
        Required?                    true
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -UseDHCP [<SwitchParameter>]
        
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -TarPath <String>
        Path to the .tar that is the base image to load into Docker.
        
        Required?                    false
        Position?                    named
        Default value                
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
#### NOTES
        Copyright (c) Microsoft Corporation.  All rights reserved.
        
        Use of this sample source code is subject to the terms of the Microsoft
        license agreement under which you licensed this sample source code. If
        you did not accept the terms of the license agreement, you are not
        authorized to use this sample source code. For the terms of the license,
        please see the license agreement between you and Microsoft or, if applicable,
        see the LICENSE.RTF on your install media or the root of your tools installation.
        THE SAMPLE SOURCE CODE IS PROVIDED "AS IS", WITH NO WARRANTIES.
    
#### Examples
    
    PS C:\>.\install-docker-ce.ps1
    
#### Prerequisites
Requires PowerShell version 5.0


## uninstall-docker-ce.ps1

#### NAME
    uninstall-docker-ce.ps1
    
#### SYNOPSIS
    Uninstalls Docker Community Edition and cleans up associated components
    
#### SYNTAX
    uninstall-docker-ce.ps1 [-Force] [-RemoveWindowsFeatures] [-KeepData] [-WhatIf] [<CommonParameters>]
    
#### DESCRIPTION
    Uninstalls Docker Community Edition, stops and removes the Docker service,
    removes Docker binaries, cleans up Docker data directory, and removes Docker networks.
    Optionally removes Windows features if they are no longer needed.

#### PARAMETERS
    -Force [<SwitchParameter>]
        If specified, bypasses user confirmation prompts and proceeds with uninstallation automatically.
        
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -RemoveWindowsFeatures [<SwitchParameter>]
        If specified, removes the Windows Container feature. Use with caution as this may affect other container runtimes.
        
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -KeepData [<SwitchParameter>]
        If specified, preserves the Docker data directory and configuration files.
        
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false
        
    -WhatIf [<SwitchParameter>]
        Shows what would be done without actually performing the uninstallation.
        
        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Accept wildcard characters?  false

#### EXAMPLES
    PS C:\>.\uninstall-docker-ce.ps1
    Prompts for confirmation before each operation
    
    PS C:\>.\uninstall-docker-ce.ps1 -Force
    Bypasses all confirmation prompts and proceeds with uninstallation
    
    PS C:\>.\uninstall-docker-ce.ps1 -Force -RemoveWindowsFeatures
    Uninstalls Docker and removes Windows Container features without prompts
    
    PS C:\>.\uninstall-docker-ce.ps1 -WhatIf
    Shows what would be uninstalled without making any changes

#### NOTES
    Copyright (c) Microsoft Corporation.  All rights reserved.
    
    Use of this sample source code is subject to the terms of the Microsoft
    license agreement under which you licensed this sample source code. If
    you did not accept the terms of the license agreement, you are not
    authorized to use this sample source code. For the terms of the license,
    please see the license agreement between you and Microsoft or, if applicable,
    see the LICENSE.RTF on your install media or the root of your tools installation.
    THE SAMPLE SOURCE CODE IS PROVIDED "AS IS", WITH NO WARRANTIES.

#### Prerequisites
Requires PowerShell version 5.0
Requires Administrator privileges
