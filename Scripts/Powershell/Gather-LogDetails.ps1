## Kaseya Automation Team
## Used by the "Gather Log Detais" Agent Procedure

param (
    [parameter(Mandatory=$true)]
    [string]$AgentName = "",
    [parameter(Mandatory=$true)]
	[string]$Path = ""
)


#Create array where all objects for export will be storred
$Results = @()

#Uncommect line below if all logs should be processed
#$Logs = Get-WMIObject Win32_NTEventLogFile

#And commect this one, if line above was uncommented
$Logs = Get-WMIObject Win32_NTEventLogFile|Where-Object {$_.Filename -eq "Security" -or $_.Filename -eq "Application" -or $_.Filename -eq "System"}

ForEach ($Log in $Logs) {

    $Output = New-Object psobject

    $LogName = $Log.FileName
    $Size = $Log.FileSize

    #Get date and convert it to human readable format
    $date = ([WMI] '').ConvertToDateTime($Log.Lastmodified)
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
$Results| Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8