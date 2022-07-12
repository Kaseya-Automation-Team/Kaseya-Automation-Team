## This script downloads and silently installs Box Drive

#Define variables
$AppName = "Box Drive"
$AppNameWithWildCard = "Box"
$URL = "https://dl2.boxcloud.com/d/1/b1!BYnYnTS2OebP-0pOhJ5eryd_OzsgbKjE2rlEQhLGUydepUX1dNlgpvw53pnEnDjM4ALQUL_NqwS51SyfFHNGIgEFeTrhVm1Pwiwc6948CrGEsTyGj7mBm111mOVa5WL_MePh0sR8hFjhCqNK6CBu46maMY5SxNJ7hZUIN4m4c2GYv-j7d8uKFTZbxRR6LTi2x5RoXxtJVhp3Wnjr6fwocPQ9oY4XURAaBMpZ4ux5dU4obLa_0uZ0e0i1Vw1s-B9CV0E59peJzSb0J6prvwDDnbDyDlEAkFMZeCW9oUR3WcTlo1SPFAzHB43evJiKUFTJEwCGfgwtbVAvpPhdT2dFbqVUuSpDrdgdzGhclf5fCYJ3WvhD2d6nTHztD9pEA0DsJQ683k8ew0YAeDiBquNDbrkq6mU8aPD3G1WfK66kI57Z1ZvBdKRNWRdBzMbKzSpdmCcMsDpqyYWq0tINJBD760_O6avXySP6xcgvAnejdRuvjTv-Ua6V3kL-meDKqUmGYlWiK8xeVz1QMX7O0OvHv3UNs0dBLMQUkxJrFB7190aiW1urZ6605bOnsti7ifi2pPwvLN0GW2F-bJqXQq8_saZcaNByUYqL6Jfq6hDy68VT-QpOBhF_cQKstlTNQT5wh62mEpERHoz4fewqIZhdYAxEPDWTnp4dDt9hSHryT5Gv4UOFzyvuFmhAZHtPez8e4i4KA9g2qScaBhr2fZeTQ9fQPVLMBPi93y0HD_hAne26GK595L67BW9OAA-k7memyONfzdMXqVbV6e0HAY3OvWgWftODBkA39Tn4Cl5WwWoPdDcqx71p-qxE-w-5sVC6wXGB-5xgaubXoZO0Nq6ebc0dEg_-FE-mdSxWVB9BcijdCirysCLatcc_H6Fbctil6aa0CgMxEHqtyTSSD5JWXT_covD-Ol6s31_1HVPT17v3YR9uVONQy-KZHTCZXJN9Q2H09qP5lZPL3_V42elI6O8LaZz7agr_E7Tc4nlS7qmhcLP3jdkjSy53ki6mEOUyxfFV07ZGFvyXFkQIni0Sxf_7F2i_kfAbsYVE-esmTWG6ccRli5ejqAUS-CpnO0mUrhS4Ag4e5KIMEjjOuqkgr0Wzfcb5nYSHDyHz6iEPArVV88doRzND2MftWmu7KQqnWzI54qZs-1skxypcWKbeu0AUB6IsCzHef4A0BQR6DdLYSDQPXG_XYdf66bw5ii4aI4m5pYBdZqhKu7_YysT5VEHTTnnhagYmFwak5v5eYMLKLm0cQfeiXvI5U6fMYN0bnEZRv--uUzI./download"
$Destination = "$env:TEMP\boxdrive.msi"

#Create VSA X Event Source if it doesn't exist
if ( -not [System.Diagnostics.EventLog]::SourceExists("VSA X")) {
    [System.Diagnostics.EventLog]::CreateEventSource("VSA X", "Application")
}

function Get-RegistryRecords {
    Param($productDisplayNameWithWildcards)

    $machine_key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    $machine_key6432 = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'

    return Get-ItemProperty -Path @($machine_key, $machine_key6432) -ErrorAction SilentlyContinue |
           Where-Object {
              $_.DisplayName -like $productDisplayNameWithWildcards
           } | Sort-Object -Property @{Expression = {$_.DisplayVersion}; Descending = $True} | Select-Object -First 1
}


#Lookup related records in Windows Registry to check if application is already installed
function Test-IsInstalled(){
    return Get-RegistryRecords($AppNameWithWildCard);
}

#Start download
function Get-Installer($URL) {

    Write-Host "Downloading $AppName installer."
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $URL -OutFile "$Destination"

    if (Test-Path -Path $Destination) {

        Start-Install
    } else {

        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Unable to download $AppName installation file.", "Error", 400)
    }
}

#Execute installer
function Start-Install() {

    Write-Host "Starting $AppName installation."
    Start-Process -FilePath "MsiExec.exe" -ArgumentList "/i $Destination /quiet /qn /norestart /log $env:TEMP\Zoom-Install.log" -Wait
}

#Delete installation file
function Start-Cleanup() {

    Write-Host "Removing installation files."
    Remove-Item -Path $Destination -ErrorAction SilentlyContinue
}

#If application is not installed yet, continue with installation
if (Test-IsInstalled -ne $null) {

    [System.Diagnostics.EventLog]::WriteEntry("VSA X", "$AppName is already installed on the target computer, not proceeding with installation.", "Warning", 300)
    Write-Host "$AppName is already installed on the target computer, not proceeding with installation."

    break

} else {
    
    [System.Diagnostics.EventLog]::WriteEntry("VSA X", "$AppName installation process has been initiated by VSA X script", "Information", 200)

    Get-Installer($URL)
    Start-Cleanup
    
    Start-Sleep -s 10

    $Installed = Test-IsInstalled

    #Verify that application has been successfully installed
    if ($null -eq $Installed) {

        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "Couldn't install $AppName on the target computer.", "Error", 400)
        Write-Host "Couldn't install $AppName on the target computer."

    } else {
        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "$AppName has been successfully installed.", "Information", 200)
        Write-Host "$AppName has been successfully installed."
    }
}