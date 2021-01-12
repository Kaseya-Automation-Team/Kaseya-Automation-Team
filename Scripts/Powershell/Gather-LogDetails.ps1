## Kaseya Automation Team
## Used by the "Gather Log Detais" Agent Procedure

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

#Create array where all objects for export will be storred
$Results = @()

#Uncommect line below if all logs should be processed
#$Logs = Get-WMIObject Win32_NTEventLogFile

#And commect this one, if line above was uncommented

try {
    $Logs = Get-WMIObject Win32_NTEventLogFile|Where-Object {$_.Filename -eq "Security" -or $_.Filename -eq "Application" -or $_.Filename -eq "System"}
    Write-Debug ($Logs | Select-Object *| Out-String)
}

catch {
    Write-Debug "Unable to execute Get-WMIObject call"
    Write-Debug $_.Exception.Message
}


ForEach ($Log in $Logs) {

    $Output = New-Object psobject

    $LogName = $Log.FileName
    $Size = $Log.FileSize

    Write-Debug ($LogName|Out-String)
    Write-Debug ($Size|Out-String)

    #Get date and convert it to human readable format
    $date = ([WMI] '').ConvertToDateTime($Log.Lastmodified)

    Write-Debug ($Log.Lastmodified|Out-String)
    Write-Debug ($date|Out-String)

    $date = Get-Date $date -Format 'MM-dd-yyyy hh:mm:ss:ms'
    $date = $date -replace "-", "/"


    Add-Member -InputObject $Output -MemberType NoteProperty -Name MachineID -Value $AgentName
    Add-Member -InputObject $Output -MemberType NoteProperty -Name LogName -Value $LogName
    Add-Member -InputObject $Output -MemberType NoteProperty -Name "LogSize (kb)" -Value $Size
    Add-Member -InputObject $Output -MemberType NoteProperty -Name LastModified -Value $date

    #Add object to the previously created array
    $Results += $Output

}

#Export results to csv file
$Results| Export-Csv -Path $Path\$Filename -NoTypeInformation -Encoding UTF8

if (1 -eq $LogIt)
{
    $Pref = "SilentlyContinue"
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}