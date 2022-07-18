## This script downloads and silently installs Greenshot

#Define variables
$AppName = "Greenshot"
$AppFullName = "Greenshot*"
$URL = "https://dl2.boxcloud.com/d/1/b1!MStzdUIK6y0-jBCZ5ec5bvqn8QssuuPezXZMh7Tlzt2FWjBZF5bhuQx0ICF5fkvuglRWa-LTL_K6uEWxz9JOXm8v14r2yELRlcAgtSMiM2WR2ItUsFBiOA85BXUqKdvTyyrRea2DD-hUoSJ7o8zwfodNDybwwxISau9mNAnWIhespu6t3P9QB06_pSjSNU-ZlcSuhTUgeuLUXp3b0IOLytr9HODOTSmRbtB6pwfxDaiLyGhjmXRLMKfpLWoxSROFnN4n_OIeBoMyvOt0wMdYnAE48wrZYXnyh9ZYjIwrjE0Weq7Wk8uL31f4jsg35zoh_TUOBp_0JbwRpTuJy52KuvRkGZjEHbGqe34gUT-_yyObhKWMSaH34v86QexgvsDzVaLtDNcDiJQq9Wz6fvotTSON9p-uI8A3JUe5vjQ2sznmtW1TtmcMQq33vHBg3hffDqpAo41eP7CGemFsnQUycRM0NqXtk_7pLduMyyq1rJOr3xx3uE5cy9fvNfPBaZrFiG8Al_4BCn7__Apm4S9SMwRamNBeyWOVs42xQBeWNR8AGTctnl3GJwaQKEGI2wSHX7W008rMqrOJu3zi1n4abESaLajwA9uxvluXvt849TqOR05TPypzS_enC1j2nxUOZVVilmDzYMGrk_BwKp6FwC2el44rR2xZYYDL8lpaZkOcaTfMUKHrfotfqcmcM8xEmgw20Kjjoo0OdX0sw0VSG-FYZ22wpDiCpHAprZOmnT5EIbfKCj1aSefK83HEyx5DBjOedvJb12Jm6W6truoBQCuVJ9CdJ_Z9NddYy04e8lxxjkZMjpLMMS4QZnTGhT4RqdJ-2r1FYEIBb_Zw7wt-R2rrour2ucZrlb4M0v-shNBWksYrZR-2ZHu5MS0_2-k9CBAWE-ddtztcLVB6f9h201Do_x1xbqYwkUgkX-7rQhSLPkqloBQh5D6vKfFUVLepmylZcaXX_RbKl92GQXlqPI8RcL5KDDSHRkafTrj3u28Lx2LvMVY6kxpiDsFXtIe5l58H2_T7_WlWCWaWA2lzTn3zGUCTQcXidRzC6CWZ_386gZhsde1ju3eHsVAMup5Ue_jTJJ0fp5wa3wDmM9Q77cOBqmlr1v-drgDfl3XNkzlJXfo5Rcf6EM_OM3SaunL2FokhT9fxSSkvFoYiTQc7KK5t8fCeHKncy1_goi_TVai6ysTriRQiQK35qKhFBZa-7jR6vonvaozEounKSwZcz2OAyfEEYiVyJuItNbmia8I8GFsvu7IFWrWW2TS3Df5uLb0lFS2sml6t-pY./download"
$Destination = "$env:TEMP\greenshot.exe"

#Create VSA Event Source if it doesn't exist
if ( -not [System.Diagnostics.EventLog]::SourceExists("VSA")) {
    [System.Diagnostics.EventLog]::CreateEventSource("VSA", "Application")
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

    Write-Host "Downloading $AppName installer."
	$ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $URL -OutFile "$Destination"

    if (Test-Path -Path $Destination) {

        Start-Install
    } else {

        [System.Diagnostics.EventLog]::WriteEntry("VSA", "Unable to download $AppName installation file.", "Error", 400)
    }
}

#Execute installer
function Start-Install() {

    Write-Host "Starting $AppName installation."
    & "$Destination" /VERYSILENT /SP- /NOCANCEL /NORESTART /SUPPRESSMSGBOXES /CLOSEAPPLICATIONS | Out-String
}

#Delete installation file
function Start-Cleanup() {

    Write-Host "Removing installation files."
    Remove-Item -Path $Destination -ErrorAction SilentlyContinue
}

#If application is not installed yet, continue with installation
if (Test-IsInstalled -ne $null) {

    [System.Diagnostics.EventLog]::WriteEntry("VSA", "$AppName is already installed on the target computer, not proceeding with installation.", "Warning", 300)
    Write-Host "$AppName is already installed on the target computer, not proceeding with installation."

    break

} else {
    
    [System.Diagnostics.EventLog]::WriteEntry("VSA", "$AppName installation process has been initiated by VSA script", "Information", 200)

    Get-Installer($URL)
    Start-Cleanup
    
    Start-Sleep -s 10

    $Installed = Test-IsInstalled

    #Verify that application has been successfully installed
    if ($null -eq $Installed) {

        [System.Diagnostics.EventLog]::WriteEntry("VSA", "Couldn't install $AppName on the target computer.", "Error", 400)
        Write-Host "Couldn't install $AppName on the target computer."

    } else {
        [System.Diagnostics.EventLog]::WriteEntry("VSA", "$AppName has been successfully installed.", "Information", 200)
        Write-Host "$AppName has been successfully installed."
    }
}