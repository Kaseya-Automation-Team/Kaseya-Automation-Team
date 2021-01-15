## Kaseya Automation Team
## Used by the "Gather Encryption Status" Agent Procedure
param (
    [parameter(Mandatory=$true)]
    [string]$AgentName = "",
    [parameter(Mandatory=$true)]
	[string]$Path = "",
    [parameter(Mandatory=$true)]
	[string]$Filename = "",
    [parameter(Mandatory=$false)]
    [int]$LogIt = 0
)

[string]$Pref = "Continue"
if (1 -eq $LogIt)
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $ScriptName = [io.path]::GetFileNameWithoutExtension( $($MyInvocation.MyCommand.Name) )
    $LogFile = "$Path\$ScriptName.log"
    Start-Transcript -Path $LogFile
}

Write-Debug "Script execution started"

$Output = New-Object psobject

Add-Member -InputObject $Output -MemberType NoteProperty -Name MachineID -Value $AgentName

$BitLockerStatus = (Get-BitLockerVolume |Select-Object -Property ProtectionStatus).ProtectionStatus

Write-Debug ($BitLockerStatus|Out-String)

if ($BitLockerStatus -eq "On") {
    Add-Member -InputObject $Output -MemberType NoteProperty -Name BitLockerStatus -Value "True"
} else {
    Add-Member -InputObject $Output -MemberType NoteProperty -Name BitLockerStatus -Value "False"
}

$RemovableDevices = Get-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\FVE\" -Name RDVConfigureBDE -ErrorAction SilentlyContinue

Write-Debug ($RemovableDevices|Out-String)

if ($RemovableDevices) {
    Add-Member -InputObject $Output -MemberType NoteProperty -Name BitLockerRemovableDeviceStatus -Value "True"
} else {
    Add-Member -InputObject $Output -MemberType NoteProperty -Name BitLockerRemovableDeviceStatus -Value "False"
}

$LegalNoticeCaption = (Get-ItemProperty -Path "HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system\” -Name legalnoticecaption).legalnoticecaption

Write-Debug ($LegalNoticeCaption|Out-String)

If ($LegalNoticeCaption) {
    Add-Member -InputObject $Output -MemberType NoteProperty -Name LegalNoticeMessage -Value "True"
}
else {
    Add-Member -InputObject $Output -MemberType NoteProperty -Name LegalNoticeMessage -Value "False"
}

Write-Debug ($Output|Out-String)

Export-Csv -InputObject $Output -Path $Path\$Filename -NoTypeInformation

if (1 -eq $LogIt)
{
    $Pref = "SilentlyContinue"
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}