Function Get-JavaInstallStatus {

    Return  (Get-Command java -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Version)

}


Function Install-UnifiController {

#UnifiController download location
$Unifi_Source = 'https://dl.ubnt.com/unifi/7.1.61/UniFi-installer.exe'

# Destination to save the Java installer
$unifi_destination = "$env:TEMP\UniFi-installer.exe"

$Unifi_Status = (Get-Package | Where-Object {$_.Name -eq "Ubiquiti UniFi (remove only)"} | Select-Object -Property Status).Status

 if ($Unifi_Status -eq "Installed") {
        Write-Host "Unifi controller is already installed on this computer!"
    } else {
        Write-Host "Unifi Controller is not installed on this computer, Proceeding with the installation!"

        #Download the file
        Invoke-WebRequest -Uri $Unifi_Source -OutFile $unifi_destination

         #Run the install command
         Start-Process -FilePath $unifi_destination -ArgumentList '/S' -Wait
         
         #Check the install status again
         $Unifi_Status = (Get-Package | Where-Object {$_.Name -eq "Ubiquiti UniFi (remove only)"} | Select-Object -Property Status).Status

         if ($Status -eq "Installed") {
            Write-Host "Installation has been successully completed"
        } else {
            Write-Host "Installation could not be completed"
        }

    }

}

$java_version = Get-JavaInstallStatus

# Java download locations and these might have to be updated to the latest versions manually as Oracle didn't have a direct link that redirects to the new version released
$source64 = 'https://javadl.oracle.com/webapps/download/AutoDL?BundleId=246474_2dee051a5d0647d5be72a7c0abff270e'
$source32 = 'https://javadl.oracle.com/webapps/download/AutoDL?BundleId=246472_2dee051a5d0647d5be72a7c0abff270e'

# Destination to save the Java installer
$java_destination = "$env:TEMP\javaSetup.exe"

if ($java_version -eq $null) {

    Write-Host "Java is not installed on this computer and installing Java"

    #Check to see if windows is 64 bit or 32 bit
     if ($env:PROCESSOR_ARCHITECTURE -match "64") {

        $source = $source64
     }

     else {

        $source = $source32

     }

     #Download the file
     Invoke-WebRequest -Uri $source -OutFile $java_destination

     #Run the install command
     Start-Process -FilePath $java_destination -ArgumentList '/s' -Wait
     

     #Check the install status again
     $java_version = Get-JavaInstallStatus


     if ($java_version -eq $null) {
     
     Write-Host "Java Could not be installed"

     }
     else {

     Write-Host "Java is Successfully installed and proceeding with the UniFi Installation!"

     Install-UnifiController
     }


}

else {

Write-Host "Java is already installed, Proceeding with the UniFi Installation.!"

Install-UnifiController

}

