Function Get-InstallStatus {

    Return  (Get-Package | Where-Object {$_.Name -eq "Intel® Driver & Support Assistant"} |  Select-Object -Property Status).Status

}


# Source file location
$source = "https://dsadata.intel.com/installer"

# Destination to save the file
$destination = "$env:TEMP\Intel-Driver-and-Support-Assistant-Installer.exe"


$status = Get-InstallStatus


if ($Status -eq "Installed"){
    
    Write-Output "Intel Driver Assistant is installed on this computer and proceeding with the un-insallation steps!"

    #Download the file
    Invoke-WebRequest -Uri $source -OutFile $destination

    #Run the install command
    Start-Process -Wait -FilePath $destination -ArgumentList '/uninstall /quiet /norestart' 

    #Deleting the installer
    Remove-Item -Path $destination -Force

    #Check the un-install status again
    $status = Get-InstallStatus
    if ($Status -ne "Installed"){
    
        Write-Output "Intel Driver Assistant is successfully un-installed on this computer!"
    }
    else{
      Write-Output "Intel Driver Assistant couldn't be un-installed on this computer!"
    }

    
}

else {

    Write-Output "Intel Driver Assistant is not installed on this computer!"

}