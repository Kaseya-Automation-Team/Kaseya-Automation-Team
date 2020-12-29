## Kaseya Automation Team
## Used by the "Gather RDP enablement status" Agent Procedure

param (
    [parameter(Mandatory=$true)]
    [string]$AgentName = "",
    [parameter(Mandatory=$true)]
	[string]$Path = ""
)

$Output = New-Object psobject

Add-Member -InputObject $Output -MemberType NoteProperty -Name MachineID -Value $AgentName

#Check if software is installed
$isInstalled = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue) | Where-Object {$_.DisplayName -like "*Bombar*"}

if ($isInstalled) {
    #If it's installed, add installed and version properties to an object
    Add-Member -InputObject $Output -TypeName Installed -MemberType NoteProperty -Name JumpClient -Value "True"
}
 else {
    #If not installed, set values to False
    Add-Member -InputObject $Output -TypeName Installed -MemberType NoteProperty -Name JumpClient -Value "False"
}

#Check if RDP connections are allowed


$RDPStatus = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -ErrorAction SilentlyContinue| Select-Object -Property fDenyTSConnections).fDenyTSConnections


If ($RDPStatus) {
    Add-Member -InputObject $Output -MemberType NoteProperty -Name RDPEnabled -Value "False"
} else {
    Add-Member -InputObject $Output -MemberType NoteProperty -Name RDPEnabled -Value "True"
}

Export-Csv -InputObject $Output -Path $Path -NoTypeInformation