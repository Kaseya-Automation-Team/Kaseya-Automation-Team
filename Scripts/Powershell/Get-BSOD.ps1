<#
.Synopsis
   Searches logs for the most recent stop error events (BSOD).
.DESCRIPTION
   Searches logs for the most recent stop error events (BSOD) within a given period of time and saves error information into a file.
   For more detailed investigation of the stop error please refer to the Bug Check Code Reference
   https://docs.microsoft.com/en-us/windows-hardware/drivers/debugger/bug-check-code-reference
.EXAMPLE
   .\Get-BSOD.ps1 -AgentName 123456 -FilePath 'C:\TEMP\bsod-data.txt'
.EXAMPLE
   .\Get-BSOD.ps1  -AgentName 123456 -FilePath 'C:\TEMP\bsod-data.txt' -PeriodInMinutes 2880 -LogIt 0
.NOTES
   Version 0.1
   Author: Proserv Team - VS
#>

param (
    [parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0)]
    [string] $AgentName,
    [parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=1)]
    [string] $FilePath,
    [parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=2)]
    [int] $PeriodInMinutes = 1440,
    [parameter(Mandatory=$false)]
    [int] $LogIt = 1
)

#region check/start transcript
[string]$Pref = 'Continue'
if ( 1 -eq $LogIt )
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $ScriptName = [io.path]::GetFileNameWithoutExtension( $($MyInvocation.MyCommand.Name) )
    $ScriptPath = Split-Path $script:MyInvocation.MyCommand.Path
    $LogFile = "$ScriptPath\$ScriptName.log"
    Start-Transcript -Path $LogFile
}
#endregion check/start transcript

Function Get-WinEventData {
<#
.SYNOPSIS
    Get custom event data from an event log record

.DESCRIPTION
    Get custom event data from an event log record

    Takes in Event Log entries from Get-WinEvent, converts each to XML, extracts all properties from Event.EventData.Data

    Notes:
        To avoid overwriting existing properties or skipping event data properties, we append 'EventData' to these extracted properties
        Some events store custom data in other XML nodes.  For example, AppLocker uses Event.UserData.RuleAndFileData

.PARAMETER Event
    One or more event.
    
    Accepts data from Get-WinEvent or any System.Diagnostics.Eventing.Reader.EventLogRecord object

.INPUTS
    System.Diagnostics.Eventing.Reader.EventLogRecord

.OUTPUTS
    System.Diagnostics.Eventing.Reader.EventLogRecord

.EXAMPLE
    Get-WinEvent -LogName system -max 1 | Get-WinEventData | Select -Property MachineName, TimeCreated, EventData*

    #  Simple example showing the computer an event was generated on, the time, and any custom event data

.EXAMPLE
    Get-WinEvent -ComputerName DomainController1 -FilterHashtable @{Logname='security';id=4740} -MaxEvents 10 | Get-WinEventData | Select TimeCreated, EventDataTargetUserName, EventDataTargetDomainName

    #  Find lockout events on a domain controller
    #    ideally you have log forwarding, audit collection services, or a product from a t-shirt company for this...

.NOTES
    Concept and most code borrowed from Ashley McGlone
        http://blogs.technet.com/b/ashleymcglone/archive/2013/08/28/powershell-get-winevent-xml-madness-getting-details-from-event-logs.aspx

.FUNCTIONALITY
    Computers
#>

    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0 )]
        [System.Diagnostics.Eventing.Reader.EventLogRecord[]]
        $event
    )

    Process
    {
        #Loop through provided events
        foreach($entry in $event)
        {
            #Get the XML...
            $XML = [xml]$entry.ToXml()
        
            #Some events use other nodes, like 'UserData' on Applocker events...
            $XMLData = $null
            if( $XMLData = @( $XML.Event.EventData.Data ) )
            {
                For( $i=0; $i -lt $XMLData.count; $i++ )
                {
                    #We don't want to overwrite properties that might be on the original object, or in another event node.
                    Add-Member -InputObject $entry -MemberType NoteProperty -name "EventData$($XMLData[$i].name)" -Value $XMLData[$i].'#text' -Force
                }
            }

            $entry
        }
    }
}

[string] $XMLQueryBSOD= @"
<QueryList>
    <Query Id="0" Path="System">
        <Select Path="System">*[System[Provider[@Name='Microsoft-Windows-WER-SystemErrorReporting'] and (Level=2) and TimeCreated[timediff(@SystemTime) &lt;= $($PeriodInMinutes*60000)]]]</Select>
        <Select Path="Application">*[System[Provider[@Name='Microsoft-Windows-WER-SystemErrorReporting'] and (Level=2) and TimeCreated[timediff(@SystemTime) &lt;= $($PeriodInMinutes*60000)]]]</Select>
        <Select Path="Security">*[System[Provider[@Name='Microsoft-Windows-WER-SystemErrorReporting'] and (Level=2) and TimeCreated[timediff(@SystemTime) &lt;= $($PeriodInMinutes*60000)]]]</Select>
        <Select Path="Setup">*[System[Provider[@Name='Microsoft-Windows-WER-SystemErrorReporting'] and (Level=2) and TimeCreated[timediff(@SystemTime) &lt;= $($PeriodInMinutes*60000)]]]</Select>
    </Query>
</QueryList>
"@
<#
#Critical system event is logged after BSOD error has been raised. It means that system was shut down to prevent data loss
[string] $XMLQueryCritical= @"
<QueryList>
    <Query Id="0" Path="System">
        <Select Path="System">
            *[System[(Level=1 )
            and 
            TimeCreated[timediff(@SystemTime) &lt;= $($PeriodInMinutes*60000)]]]
            and
            *[EventData[Data[@Name="BugcheckCode"] and (Data !='')]]
        </Select>
    </Query>
</QueryList>
"@
#>

$BSODData = Get-WinEvent -FilterXml $XMLQueryBSOD -MaxEvents 1 | Get-WinEventData

if( $null -ne $BSODData )
{
    #only properties that have values
    [array] $PopulatedProperties = $($BSODData.PSObject.Properties | Where-Object {$null -ne $_.Value} | Select-Object -ExpandProperty Name)
    $BSODData = $BSODData | Select-Object $PopulatedProperties
    #Proper date format
    [string]$DateFormat = "{0:MM'/'dd'/'yyyy H:mm:ss}"
    #Load code reference
    [string] $BSODCodesPath = Join-Path -Path $ScriptPath -ChildPath 'BSOD-codes.xml'
    
    if( Test-Path -Path $BSODCodesPath )
    {
        #Find & replace stop code with meaningful values
        $BSODCodes = Import-Clixml -Path $BSODCodesPath
        #The EventDataparam1 field contains error codes
        if ($BSODData.EventDataparam1 -match '\w+')
        {
            #first code in the field EventDataparam1 is the stop code
            $StopCode = $BSODCodes.$($Matches[0])
            Add-Member -InputObject $BSODData -MemberType NoteProperty -Name StopCode -Value $StopCode
        }
        #The EventDataparam1 field may also contain Bugcheck Parameters as a comma-separated list in parentheses
        if ($BSODData.EventDataparam1 -match '\(\w+(?:,\s*\w+)*\)')
        {
            [int] $ParamNumber = 1
            $AdditionalParams = $Matches[0]
            [regex]::Matches($AdditionalParams, '\w+') | `
                Select-Object -ExpandProperty Value | `
                    ForEach-Object {
                        Add-Member -InputObject $BSODData -MemberType NoteProperty -Name "BugcheckParameter$ParamNumber" -Value $_
                        $ParamNumber++
                    }
        }

        $BSODData = $BSODData | Select-Object -Property `
                @{Name = 'AgentGuid'; Expression = {$AgentName}}, `
                @{Name = 'MemoryDump'; Expression = {$_.EventDataparam2}}, `
                @{Name = 'ReportID'; Expression = {$_.EventDataparam3}}, `
                @{Name = 'Time Created'; Expression = { $($DateFormat -f ($_.TimeCreated)) }}, `
                * -ExcludeProperty EventDataparam2, EventDataparam3, TimeCreated, Properties
    }
    
    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
    [System.IO.File]::WriteAllLines($FilePath, $BSODData, $Utf8NoBomEncoding)
}

#region check/stop transcript
if ( 1 -eq $LogIt )
{
    $Pref = 'SilentlyContinue'
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}
#endregion check/stop transcript