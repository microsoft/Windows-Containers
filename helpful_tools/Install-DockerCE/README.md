# Install & Uninstall Docker CE

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
    
#### EXAMPLES
    
    PS C:\> .\install-docker-ce.ps1
    
#### PREREQUISITES
Requires PowerShell version 5.0

## uninstall-docker-ce.ps1

#### NAME
    uninstall-docker-ce.ps1

#### SYNOPSIS
    Uninstalls Docker Community Edition and removes related components

#### SYNTAX
    uninstall-docker-ce.ps1 [-Force] [-KeepImages] [-KeepVolumes] [-KeepNetworks]

#### DESCRIPTION
    Uninstalls Docker Community Edition from Windows, including the service,
    binaries, images, networks, containers, and volumes by default.

#### PARAMETERS
    -Force [<SwitchParameter>]
        If specified, skips confirmation prompts and forces removal
        
        Required?                    false
        Position?                    named
        Default value                false
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -KeepImages [<SwitchParameter>]
        If specified, preserves images
        
        Required?                    false
        Position?                    named
        Default value                false
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -KeepVolums [<SwitchParameter>]
        If specified, preserves volumes
        
        Required?                    false
        Position?                    named
        Default value                false
        Accept pipeline input?       false
        Accept wildcard characters?  false

    -KeepNetworks [<SwitchParameter>]
        If specified, preserves custom networks
        
        Required?                    false
        Position?                    named
        Default value                false
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

#### EXAMPLES
    PS C:\> .\uninstall-docker-ce.ps1
    Complete uninstall (removes everything: service, binaries, containers, volumes, images, networks, and data)

    PS C:\> .\uninstall-docker-ce.ps1 -Force
    Complete uninstall without confirmation prompts

    PS C:\> .\uninstall-docker-ce.ps1 -KeepImages
    Uninstall but preserve images

#### PREREQUISTES
Requires PowerShell version 5.0 and Administrator privileges