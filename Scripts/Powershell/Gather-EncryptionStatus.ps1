## Kaseya Automation Team
## Used by the "Gather Encryption Status" Agent Procedure
param (
    [parameter(Mandatory=$true)]
    [string]$AgentName = "",
    [parameter(Mandatory=$true)]
	[string]$Path = ""
)

$Output = New-Object psobject

Add-Member -InputObject $Output -MemberType NoteProperty -Name MachineID -Value $AgentName

$BitLockerStatus = (Get-BitLockerVolume |Select-Object -Property ProtectionStatus).ProtectionStatus

if ($BitLockerStatus -eq "On") {
    Add-Member -InputObject $Output -MemberType NoteProperty -Name BitLockerStatus -Value "True"
} else {
    Add-Member -InputObject $Output -MemberType NoteProperty -Name BitLockerStatus -Value "False"
}

$RemovableDevices = Get-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\FVE\" -Name RDVConfigureBDE -ErrorAction SilentlyContinue

if ($RemovableDevices) {
    Add-Member -InputObject $Output -MemberType NoteProperty -Name BitLockerRemovableDeviceStatus -Value "True"
} else {
    Add-Member -InputObject $Output -MemberType NoteProperty -Name BitLockerRemovableDeviceStatus -Value "False"
}

$LegalNoticeCaption = (Get-ItemProperty -Path "HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system\” -Name legalnoticecaption).legalnoticecaption

If ($LegalNoticeCaption) {
    Add-Member -InputObject $Output -MemberType NoteProperty -Name LegalNoticeMessage -Value "True"
}
else {
    Add-Member -InputObject $Output -MemberType NoteProperty -Name LegalNoticeMessage -Value "False"
}

Export-Csv -InputObject $Output -Path $Path -NoTypeInformation
