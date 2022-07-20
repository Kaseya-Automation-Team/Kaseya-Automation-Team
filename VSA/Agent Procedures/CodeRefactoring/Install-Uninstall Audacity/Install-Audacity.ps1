## This script downloads and silently installs Audacity 2.2.2
param (
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()] 
    [string] $URL
)
if ($URL -eq 'Test') {
    $URL = 'https://dl2.boxcloud.com/d/1/b1!LlJaQ5BooVBnnRvw5hXE_68_JVCzwWJ7neSFNJ3jfukDjTuG3rnfvECt3XTMBX0RAWRsqGP2lC_1LrsYoYUOy3cWoFSNGUc6RkKlA7d1ryWhJRw-hL8qy_rgKw-a41jsiM26GBNr96lIOK63nzG1sJKH-AZNsh13ibK2QtrS80jt-ars_zGxnPM1tnjnha6_dcMkbPxz401d4o73R1oWBTtN11ZUiJCyXB2GWHoAgcWgOhD-5883bq-DDFmoVVgQYZnk2PvQAzFhU54n9mcaAxXNQrpvpaMzUzDClCJRHduBqD40zNY4ROkJrid3sOKFAiJHeVTXOwYKq3cHYAmYeQAyhOgCrdplQW2wGh5SQHjgpcDlppZt-AbXN07fDuPABl8l9uMFbgYczHBbbrPTzxarIlU4A12pns6BzGfP-f7q0CyjdTDmXGu10UL2z9FGWbwuaSzCUkJWs_DY3B0u5ylNHF0ve6tYm-6y7Up2vNVSnxLCvZmlaQOLA8iQyfCdur0ibk2RLH1QjWCF56SniGyVFCAsk_VIBRsttoOwWrTWzN-q4UWv0jk856h6nIHfYuz0lvXLqBhQYmEBzrLG1PYEsnqXCTVwPWtI4A95w3kdox47vMRhtIBfSIi6n5c7_rebUz5SLHQt7GlCKz23tFp0ERFRVsQZQvOCFcbq-UJ94Auz5Ew74QXPI2e226Hghp8ZMNbMb3hWaOAUnUHxPMAc0FgSugQu2g8q7kLuQvPDOln9I2opujrV-hSdFJAn7FO0FCY5HJkeaAKxSqJNa8cZwZ5qpTvyRPjvQvE8hLRuutUxba2oPOLoK8qr8ww3-KRsSJiXsl2xF6uYatOyv2zYsKhMzA0kTuMaXRqbh3Eum2kSXsf5YzhHahbW4MOis2h2orbKIQWdNIiE5N-HzsBjQq2VrfRrVaLqL_IsGUoZ_3UrMD9Xn9SqhBapheQMQrJ_o9-6aTCgQ0Ss0I-3jqvCnLtUzb2mYUdHiba61S7zCRtikM2KFoXD2hyYdH8kx5Dx2IhZEql8olnXdMAuLD3TbM9kwBVqXAugproVJjs5-b5hjo1f9BGNm_YLwjb60QF21usdTPqi86zamJXW1xtSksGrRPNUwx0dUv2wVEeGvB6tYLNXXE2Jd7Q4Kjni8W4iK3WVVPZEWwJat7ND6hFs9Rb3h76WDc_A4KFDwJaXvQxxA8zoAEQ6Z1snMkub2NmBrtIlziJqGSRfdmJDPUsR-kINTK4_WgfVsMY3eSl6k3Izm5jJAJABMnltd6plkLf27-seYXKJAjZ4Iw4J00nXdOUv-OlIhTdzJjTu_9duNZI./download'
}

#Define variables
$AppName = "Audacity"
$AppFullName = "Audacity*"
$Destination = "$env:TEMP\audacity.exe"

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
    return Get-RegistryRecords($AppFullName);
}

#Start download
function Get-Installer($URL) {

    Write-Output "Downloading $AppName installer."
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

    Write-Output "Starting $AppName installation."
    Start-Process -FilePath $Destination -ArgumentList "/VERYSILENT /NORESTART" -Wait
}

#Delete installation file
function Start-Cleanup() {

    Write-Output "Removing installation files."
    Remove-Item -Path $Destination -ErrorAction SilentlyContinue
}

#If application is not installed yet, continue with installation
if (Test-IsInstalled -ne $null) {

    [System.Diagnostics.EventLog]::WriteEntry("VSA X", "$AppName is already installed on the target computer, not proceeding with installation.", "Warning", 300)
    Write-Output "$AppName is already installed on the target computer, not proceeding with installation."

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
        Write-Output "Couldn't install $AppName on the target computer."

    } else {
        [System.Diagnostics.EventLog]::WriteEntry("VSA X", "$AppName has been successfully installed.", "Information", 200)
        Write-Output "$AppName has been successfully installed."
    }
}