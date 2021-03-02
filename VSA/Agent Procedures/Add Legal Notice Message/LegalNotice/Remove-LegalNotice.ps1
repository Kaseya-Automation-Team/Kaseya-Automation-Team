## Kaseya Automation Team
## Used by the "Add Legal Notice Message" Agent Procedure
param (
    [parameter(Mandatory=$true)]
    [string]$Path = "",
    [parameter(Mandatory=$false)]
    [int]$LogIt = 0
)

[string]$Pref = "Continue"
if (1 -eq $LogIt)
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $LogFile = "$Path\Remove-LegalNotice.log"
    Start-Transcript -Path $LogFile
}

Write-Debug "Script execution started"

try {
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\policies\system\" -Name legalnoticecaption -Value "" -ErrorAction Stop
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\policies\system\" -Name legalnoticetext -Value "" -ErrorAction Stop
} catch {
    Write-Host $_.Exception.Message
}
finally {
    $LegalNoticeCaption = (Get-ItemProperty -Path "HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system\” -Name legalnoticecaption).legalnoticecaption
    $LegalNoticeText = (Get-ItemProperty -Path "HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system\” -Name legalnoticetext).legalnoticetext

    if ("$LegalNoticeCaption -eq $null" -and "$LegalNoticeText -eq $null") {
        Write-Host "Legal notice message and caption have been successfully removed."
    } else  {
        Write-Host "Unable to remove legal notice message"
    }
}

if (1 -eq $LogIt)
{
    $Pref = "SilentlyContinue"
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}