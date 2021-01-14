## Kaseya Automation Team
## Used by the "Gather Log Detais" Agent Procedure

param (
    [parameter(Mandatory=$true)]
    [string]$AgentName = "",
    [parameter(Mandatory=$true)]
    [string]$FileName = "",
    [parameter(Mandatory=$true)]
    [string]$Path = "",
    [parameter(Mandatory=$true)]
    [int]$Days = "",
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

#Count start date and end date specify a time period for Get-Event log commandlet
$AfterDate = (Get-date).AddDays(-$Days)
$BeforeDate = Get-Date

Write-Debug ($BeforeDate|Out-String)
Write-Debug ($AfterDate|Out-String)


$AllEvents = Get-EventLog Security -InstanceId 4625 -After $AfterDate -Before $BeforeDate | Select-Object -Property Timegenerated, Message | Where-Object {$_.Message.Contains("User32")}

Write-Debug ($AllEvents|Out-String)

If ($AllEvents -eq $null) {
    $Output = New-Object psobject

    Add-Member -InputObject $Output -MemberType NoteProperty -Name AgentGuid -Value $AgentName
    Add-Member -InputObject $Output -TypeName Username -MemberType NoteProperty -Name Username -Value "NULL"
    Add-Member -InputObject $Output -TypeName DateTime -MemberType NoteProperty -Name DateTime -Value "NULL"
    $Results += $Output

} else {

    ForEach ($Event in $AllEvents) {

        #Create new obect
        $Output = New-Object psobject

        Add-Member -InputObject $Output -MemberType NoteProperty -Name AgentGuid -Value $AgentName

        $Message = $Event.Message

        Write-Debug ($Time|Out-String)

        $matches = ([regex]'(?m)\s+Account Name:\s+(.+)$').Matches($Message)

        Write-Debug ($matches|Out-String)

        $UserName = $matches[1].Groups[1].Value.Trim()

        Write-Debug ($UserName|Out-String)

        If ($UserName -ne $null) {
            Add-Member -InputObject $Output -TypeName Username -MemberType NoteProperty -Name Username -Value $UserName
        } else {
            Add-Member -InputObject $Output -TypeName Username -MemberType NoteProperty -Name Username -Value "NULL"
        }

        $Time = $Event.TimeGenerated

        write-Debug ($Time|Out-String)

        $Time = Get-Date $Time -Format 'MM/dd/yyyy hh:mm:ss:ms'
        $Time = $Time -replace "-", "/"

        Write-Debug ($Time|Out-String)

        If ($UserName -ne $null) {
            Add-Member -InputObject $Output -TypeName Username -MemberType NoteProperty -Name DateTime -Value $Time
        } else {
            Add-Member -InputObject $Output -TypeName Username -MemberType NoteProperty -Name DateTime -Value "NULL"
        }
        #Add object to the previously created array
        $Results += $Output
    }

}

Write-Debug ($Results|Out-String)

#Export results to csv file
$Results| Export-Csv -Path $Path\$FileName -NoTypeInformation -Encoding UTF8

if (1 -eq $LogIt)
{
    $Pref = "SilentlyContinue"
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}