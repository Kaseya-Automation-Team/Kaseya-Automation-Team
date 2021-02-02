<#
.Synopsis
   Searches the Security log for the most recent events of a specific IDs and returns user related.
.DESCRIPTION
   Searches the Security log for the most recent events of a specific IDs and saves user information into a file.
   The script is used in the PS-Monitor Logins VSA Agent Procedure
.EXAMPLE
   .\Get-LoginEvents.ps1 4624 'C:\Temp'
.EXAMPLE
   .\Get-LoginEvents.ps1 -EventID 4625 -Path 'C:\Temp' -LogIt 1
.NOTES
   Version 0.2
   Author: Proserv Team - VS
#>

param (
    
[parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0)]
    [int] $EventID,
    [parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=1)]
    [string] $Path,
    [parameter(Mandatory=$false)]
    [int] $LogIt = 0
)

#region check/start transcript
[string]$Pref = 'Continue'
if ( 1 -eq $LogIt )
{
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    $ScriptName = [io.path]::GetFileNameWithoutExtension( $($MyInvocation.MyCommand.Name) )
    $LogFile = "$path\$ScriptName.log"
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



switch ( $EventID )
{
## Successful Login
    4624 {
        $FileName = 'login.txt'
        [array] $SelectFields = @('EventDataTargetUserName', 'EventDataTargetDomainName', 'EventDataElevatedToken')
        [string] $XMLQuery= @"
<QueryList>
  <Query Id="0"
         Path="Security">
    <Select Path="Security">
*[System[(EventID=4624)]]
and
(
(*[EventData[Data[@Name="LogonType"] and (Data='2')]]) or
(*[EventData[Data[@Name="LogonType"] and (Data='3')]]) or
(*[EventData[Data[@Name="LogonType"] and (Data='10')]]) or
(*[EventData[Data[@Name="LogonType"] and (Data='11')]])
)
    </Select>
  </Query>
</QueryList>
"@

        Get-WinEvent -FilterXml $XMLQuery -MaxEvents 1 | Get-WinEventData | Select-Object $SelectFields `
        | ForEach-Object {
                if($_.EventDataElevatedToken -match '1842')
                {
                    $OutputData += "Admin $($_.EventDataTargetDomainName)\$($_.EventDataTargetUserName)"                            
                }
                else
                {
                    $OutputData += "$($_.EventDataTargetDomainName)\$($_.EventDataTargetUserName)"
                }
            }
    } #4624

## User Logged Off
    4634 {
        $FileName = 'logout.txt'
                [hashtable] $LogFilter = @{
                    LogName = 'Security'
                    ID = $EventID
                    }

        [hashtable] $WinEventArgs = @{
                    Computer = $env:ComputerName
                    FilterHashtable = $LogFilter
                    maxEvents = 1
                    }

        Get-WinEvent @WinEventArgs | Get-WinEventData | Select-Object $SelectFields `
            | ForEach-Object { $OutputData += "$($_.EventDataTargetDomainName)\$($_.EventDataTargetUserName)" }
    } #4634

## Failed to Login
    4625 {
        $FileName = 'failed.txt'
        [hashtable] $LogFilter = @{
                    LogName = 'Security'
                    ID = $EventID
                    }

        [hashtable] $WinEventArgs = @{
                    Computer = $env:ComputerName
                    FilterHashtable = $LogFilter
                    maxEvents = 1
                    }

        Get-WinEvent @WinEventArgs | Get-WinEventData | Select-Object $SelectFields `
            | ForEach-Object { $OutputData += "$($_.EventDataTargetDomainName)\$($_.EventDataTargetUserName)" }
        } #4625

## Account Locked Out
    4740 {
        $FileName = 'lockedout.txt'
        [array] $SelectFields = @('EventDataTargetUserName', 'EventDataTargetDomainName')
        [hashtable] $LogFilter = @{
                    LogName = 'Security'
                    ID = $EventID
                    }

        [hashtable] $WinEventArgs = @{
                    Computer = $env:ComputerName
                    FilterHashtable = $LogFilter
                    maxEvents = 1
                    }

        Get-WinEvent @WinEventArgs | Get-WinEventData | Select-Object $SelectFields `
            | ForEach-Object { $OutputData += "$($_.EventDataTargetDomainName)\$($_.EventDataTargetUserName)" }
    } #4740
}

$OutputData | Out-File -FilePath "$Path\$FileName" -Encoding UTF8 -Force

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