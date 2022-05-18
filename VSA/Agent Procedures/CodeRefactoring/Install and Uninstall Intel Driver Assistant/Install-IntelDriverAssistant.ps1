Function Get-InstallStatus {

    Return  (Get-Package | Where-Object {$_.Name -eq "Intel® Driver & Support Assistant"} |  Select-Object -Property Status).Status

}


# Source file location
$source = "https://dsadata.intel.com/installer"

# Destination to save the file
$destination = "$env:TEMP\Intel-Driver-and-Support-Assistant-Installer.exe"


$status = Get-InstallStatus


if ($Status -ne "Installed"){
    
    Write-Host "Intel Driver Assistant is not installed on this computer and proceeding with the insallation steps!"

    #Download the file
    Invoke-WebRequest -Uri $source -OutFile $destination

    #Run the install command
    Start-Process -Wait -FilePath $destination -ArgumentList '/install /quiet /norestart' 

    #Check the install status again
    $status = Get-InstallStatus
    if ($Status -eq "Installed"){
    
        Write-Host "Intel Driver Assistant is successfully installed on this computer!"
    }
    else{
      Write-Host "Intel Driver Assistant is not installed!"
    }

}
else {

    Write-Host "Intel Driver Assistant is already installed on this computer!"

}