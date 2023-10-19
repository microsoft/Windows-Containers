#################################################################
# Script to uninstall the community edition of docker on Windows
#################################################################

# Check if any containers are still running
docker ps

$answer = Read-Host "Make sure there are no containers running and that all images you want to save are published. Do you want to continue? (Y/N)"

if ($answer -eq 'Y' -or $answer -eq 'y') {
    Write-Host "Uninstalling Docker."

    #Halt the docker service
    Stop-Service -Name docker

    #Unregister the docker service
    dockerd --unregister-service

    #Remove the docker binary
    Remove-Item -Path C:\ProgramData\docker -Recurse

    $service = Get-Service -Name "docker" -ErrorAction SilentlyContinue
    if ($service -eq $null) {
        Write-Host "Docker uninstall completed"
    } else {
        Write-Host "Could not verify docker service was uninstalled"
    }
} else {
    Write-Host "Exiting."
}
