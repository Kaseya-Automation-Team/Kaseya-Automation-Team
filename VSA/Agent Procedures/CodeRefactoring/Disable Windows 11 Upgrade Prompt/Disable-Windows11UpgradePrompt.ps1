<#
=================================================================================
Script Name:        Management: Disable Windows 11 Upgrade Prompt
Description:        This script modifies Windows Registry keys to make sure system will stay with latest Windows 10 release and will not suggest upgrade to Windows 11.
Lastest version:    2022-09-20
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>
#Registry path to Windows Update settings
$Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\"

#Test if registry path already exists. Otherwise, create it
if (!(Test-Path "$Path")) {
    New-Item -Path $Path -Force | Out-Null
    eventcreate /L Application /T INFORMATION /SO "VSA X" /ID 200 /D "Registry path $Path didn't exist and has been created by VSA X script." | Out-Null
}

#Prevent upgrades and specify latest Windows 10 release as version to stay with
$TargetReleaseVersionKey = (Get-Item -Path $Path).GetValue("TargetReleaseVersion") -ne $null
$ProductVersion = (Get-Item -Path $Path).GetValue("ProductVersion") -ne $null

#If registry key doesn't exist, create one. Otherwise, update the value of existing key
if ($TargetReleaseVersionKey -eq $null) {
    New-ItemProperty -Path $Path -Name "TargetReleaseVersion" -Value "1" -PropertyType DWord
} else {
    Set-ItemProperty -Path $Path -Name "TargetReleaseVersion" -Value "1"
}

#If registry key doesn't exist, create one. Otherwise, update the value of existing key
if ($ProductVersion -eq $null) {
    New-ItemProperty -Path $Path -Name "ProductVersion" -Value "21H2" -PropertyType String
} else {
    Set-ItemProperty -Path $Path -Name "ProductVersion" -Value "21H2"
}

eventcreate /L Application /T INFORMATION /SO "VSA X" /ID 200 /D "Windows Registry settings have been modified by VSA X script, to prevent upgrade to Windows 11." | Out-Null