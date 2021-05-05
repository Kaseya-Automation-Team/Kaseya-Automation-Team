## Kaseya Automation Team
## Used by the "Gather RDP enablement status" Agent Procedure

param (
    [parameter(Mandatory=$true)]
    [string]$AgentName = "",
    [parameter(Mandatory=$true)]
	[string]$Path = "",
    [parameter(Mandatory=$true)]
	[string]$FileName = "",
    [parameter(Mandatory=$false)]
    [int]$LogIt = 0
)

[string]$Pref = "Continue"
if (1 -eq $LogIt)
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $ScriptName = [io.path]::GetFileNameWithoutExtension($($MyInvocation.MyCommand.Name))
    $LogFile = "$Path\$ScriptName.log"
    Start-Transcript -Path $LogFile
}

Write-Debug "Script execution started"

$Output = New-Object psobject

Add-Member -InputObject $Output -MemberType NoteProperty -Name MachineID -Value $AgentName

#Check if software is installed
try {

    $isInstalled = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction SilentlyContinue) | Where-Object {$_.DisplayName -like "*Bomgar*"}

    Write-Debug ($isInstalled|Out-String)

    if ($isInstalled) {
        #If it's installed, add installed and version properties to an object
        Add-Member -InputObject $Output -TypeName Installed -MemberType NoteProperty -Name JumpClient -Value "True"
    }
     else {
        #If not installed, set values to False
        Add-Member -InputObject $Output -TypeName Installed -MemberType NoteProperty -Name JumpClient -Value "False"
    }
}
catch {
    Add-Member -InputObject $Output -TypeName Installed -MemberType NoteProperty -Name JumpClient -Value "False"
}

#Check if RDP connections are allowed
$RDPStatus = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -ErrorAction SilentlyContinue| Select-Object -Property fDenyTSConnections).fDenyTSConnections

Write-Debug ($RDPStatus|Out-String)

If ($RDPStatus) {
    Add-Member -InputObject $Output -MemberType NoteProperty -Name RDPEnabled -Value "False"
} else {
    Add-Member -InputObject $Output -MemberType NoteProperty -Name RDPEnabled -Value "True"
}

Write-Debug ($Output|Out-String)

Export-Csv -InputObject $Output -Path $Path\$FileName -NoTypeInformation

if (1 -eq $LogIt)
{
    $Pref = "SilentlyContinue"
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}