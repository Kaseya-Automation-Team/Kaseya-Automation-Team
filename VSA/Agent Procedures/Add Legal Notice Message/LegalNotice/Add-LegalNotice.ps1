## Kaseya Automation Team
## Used by the "Add Legal Notice Message" Agent Procedure
param (
    [parameter(Mandatory=$true)]
    [string]$Path = '',
    [parameter(Mandatory=$true)]
    [string]$NewLegalNoticeCaption = '',
    [parameter(Mandatory=$true)]
	[string]$NewLegalNoticeMessage = '',
    [parameter(Mandatory=$false)]
    [int]$LogIt = 0
)

[string]$Pref = "Continue"
if (1 -eq $LogIt)
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $LogFile = "$Path\Add-LegalNotice.log"
    Start-Transcript -Path $LogFile
}

Write-Debug "Script execution started"
Write-Debug "New values:"
Write-Debug ($NewLegalNoticeCaption|Out-String)
Write-Debug ($NewLegalNoticeMessage|Out-String)

try {
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\policies\system\" -Name legalnoticecaption -Value $NewLegalNoticeCaption -ErrorAction Stop
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\policies\system\" -Name legalnoticetext -Value $NewLegalNoticeMessage -ErrorAction Stop
} catch {
    Write-Host $_.Exception.Message
}
finally {
    $LegalNoticeCaption = (Get-ItemProperty -Path "HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system\” -Name legalnoticecaption).legalnoticecaption
    $LegalNoticeText = (Get-ItemProperty -Path "HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system\” -Name legalnoticetext).legalnoticetext

    Write-Debug "Current values:"
    Write-Debug ($LegalNoticeCaption|Out-String)
    Write-Debug ($LegalNoticeText|Out-String)

    if ("$LegalNoticeCaption -eq $NewLegalNoticeCaption" -and "$LegalNoticeText -eq $NewLegalNoticeMessage") {
        Write-Host "Legal notice message and caption have been successfully changed."
    } else  {
        Write-Host "Unable to change legal notice message"
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