<#
=================================================================================
Script Name:        Management: Set Login Message.
Description:        Set Login Message.
Lastest version:    2022-04-11
=================================================================================



Required variable inputs:
None



Required variable outputs:
None
#>
# Inputs
$Caption = "Caption goes here"
$Text = "Text goes here"
#Registry path to Windows Update settings
$Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\"

#Test if registry path already exists. Otherwise, create it
if (!(Test-Path "$Path")) {
    New-Item -Path $Path -Force | Out-Null
    eventcreate /L Application /T INFORMATION /SO "VSA X" /ID 200 /D "Registry path $Path didn't exist and has been created by VSA X script." | Out-Null
}

$LegalNoticeCaption = (Get-Item -Path $Path).GetValue("legalnoticecaption") -ne $null
$LegalNoticeText = (Get-Item -Path $Path).GetValue("legalnoticetext") -ne $null

#If registry key doesn't exist, create one. Otherwise, update the value of existing key
if ($LegalNoticeCaption -eq $null) {
    New-ItemProperty -Path $Path -Name "legalnoticecaption" -Value $Caption -PropertyType String
} else {
    Set-ItemProperty -Path $Path -Name "legalnoticecaption" -Value $Caption
}

#If registry key doesn't exist, create one. Otherwise, update the value of existing key
if ($LegalNoticeText -eq $null) {
    New-ItemProperty -Path $Path -Name "legalnoticetext" -Value $Text -PropertyType String
} else {
    Set-ItemProperty -Path $Path -Name "legalnoticetext" -Value $Text
}

eventcreate /L Application /T INFORMATION /SO "VSA X" /ID 200 /D "Login message has been added to the system by VSA X script." | Out-Null