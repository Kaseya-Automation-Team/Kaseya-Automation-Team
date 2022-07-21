param (
    [parameter(Mandatory=$false)]
    [string] $URL ="https://dsadata.intel.com/installer",
    [parameter(Mandatory=$false)]
    [string] $Destination = "$env:TEMP\Intel-Driver-and-Support-Assistant-Installer.exe"
)

Function Get-InstallStatus {

    Return  (Get-Package | Where-Object {$_.Name -eq "Intel® Driver & Support Assistant"} |  Select-Object -Property Status).Status

}


$status = Get-InstallStatus


if ($Status -ne "Installed"){
    
    Write-Output "Intel Driver Assistant is not installed on this computer and proceeding with the insallation steps!"

    #Download the file
    Invoke-WebRequest -Uri $URL -OutFile $destination

    #Run the install command
    Start-Process -Wait -FilePath $destination -ArgumentList '/install /quiet /norestart' 

    #Deleting the installer
    Remove-Item -Path $destination -Force

    #Check the install status again
    $status = Get-InstallStatus
    if ($Status -eq "Installed"){
    
        Write-Output "Intel Driver Assistant is successfully installed on this computer!"
    }
    else{
      Write-Output "Intel Driver Assistant is not installed!"
    }

}
else {

    Write-Output "Intel Driver Assistant is already installed on this computer!"

}