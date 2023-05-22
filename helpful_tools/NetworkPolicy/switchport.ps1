function GetRuless { 
    param(
         [Parameter(mandatory=$true)]
         [string] $portName
         )
    $command  = 'c:\windows\system32\vfpctrl.exe /list-rule /port "{0}"' -f $portName
    Write-Output $command
    Invoke-Expression $command | Out-File "d:\perf\$portName.Rule.log"
}

function GetLayers { 
    param(
         [Parameter(mandatory=$true)]
         [string] $portName
         )
    $command  = 'c:\windows\system32\vfpctrl.exe /list-layer /port "{0}"' -f $portName
    Write-Output $command
    Invoke-Expression $command | Out-File "d:\perf\$portName.layer.log"
}

function GetGroups { 
    param(
         [Parameter(mandatory=$true)]
         [string] $portName
         )
    $command  = 'c:\windows\system32\vfpctrl.exe /list-group /port "{0}"' -f $portName
    Write-Output $command
    Invoke-Expression $command | Out-File "d:\perf\$portName.group.log"
}



$switchPorts=vfpctrl  /list-vmswitch-port
foreach($port in $switchPorts)
{
    if ($port.StartsWith("Port name"))
    {
        $portparts = $port.split(":")
        $portName = $portparts[1].trim()
        Write-Output $portName
        GetLayers $portName
        GetGroups $portName
        GetRuless $portName
    } 
}