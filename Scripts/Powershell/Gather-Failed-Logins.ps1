param (
    [parameter(Mandatory=$true)]
    [string]$AgentName = "",
    [parameter(Mandatory=$true)]
    [string]$FileName = "",
    [parameter(Mandatory=$true)]
    [string]$Path = "",
    [parameter(Mandatory=$true)]
    [int]$Days = ""
 )

<#
.Synopsis
   Saves all events related to failed login into csv file
.DESCRIPTION
   Gets all local events with id 4625 (Failed login) and collects username and date/time for them.
.EXAMPLE
   .\Get-FailedLogins.ps1 -AgentName "432423422" -Path "c:\kworking" -Filename "failed_logins.csv" -Days 30
.NOTES
   Version 0.2
   Author: Aliaksandr Serzhankou
   Email: a.serzhankou@kaseya.com
#>

#Create array where all objects for export will be storred
$Results = @()

#Count start date and end date specify a time period for Get-Event log commandlet
$AfterDate = (Get-date).AddDays(-$Days)
$BeforeDate = Get-Date

$AllEvents = Get-EventLog Security -InstanceId 4625 -After $AfterDate -Before $BeforeDate | Select-Object -Property Timegenerated, Message | Where-Object {$_.Message.Contains("User32")}


ForEach ($Event in $AllEvents) {

    #Create new obect
    $Output = New-Object psobject

    $Message = $Event.Message

    $Time = $Event.TimeGenerated
    $Time = Get-Date $Time -Format 'MM/dd/yyyy hh:mm:ss:ms'
    $Time = $Time -replace "-", "/"

    $matches = ([regex]'(?m)\s+Account Name:\s+(.+)$').Matches($Message)
    $UserName = $matches[1].Groups[1].Value.Trim()

    Add-Member -InputObject $Output -MemberType NoteProperty -Name AgentGuid -Value $AgentName
    Add-Member -InputObject $Output -TypeName Username -MemberType NoteProperty -Name Username -Value $UserName
    Add-Member -InputObject $Output -TypeName DateTime -MemberType NoteProperty -Name DateTime -Value $Time

    #Add object to the previously created array
    $Results += $Output
}

#Export results to csv file
$Results| Export-Csv -Path $Path\$FileName -NoTypeInformation -Encoding UTF8
