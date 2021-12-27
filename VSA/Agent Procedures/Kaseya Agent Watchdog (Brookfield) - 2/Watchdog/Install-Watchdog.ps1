## Kaseya Automation Team
## Used by the "Kaseya Agent Watchdog for Brookfield" Agent Procedure

param (
    [parameter(Mandatory=$true)]
	[string]$Path = "",
    [parameter(Mandatory=$true)]
    [int]$Minutes,
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

#Path to Kaseya Agent Watchdog script
$ScriptPath = "$Path\Watch-AgentService.ps1"

#Check if task already exists
$TaskExists = Get-ScheduledTask -TaskName "Kaseya Agent Watchdog" -ErrorAction SilentlyContinue

if ($TaskExists) {
    Write-Host "Task already exists - no need to create."
    Write-Debug($TaskExists|Out-String)
} else {
    Write-Host "Task doesn't exist and will be created"

    try {

        #If task doesn't exist, create it using specified options
        $TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-file ""$ScriptPath`""

        $Repeat = (New-TimeSpan -Minutes $Minutes)

        $TaskTrigger = New-ScheduledTaskTrigger -Once -At ((Get-Date) + $Repeat) -RepetitionInterval $Repeat

        Register-ScheduledTask -TaskName "Kaseya Agent Watchdog" -User "System" -Action $TaskAction -Trigger $TaskTrigger -Description "Restart Kaseya services if they are not in the Running state" -ErrorAction Stop

        Write-Host "Task successfully created."

        Start-ScheduledTask -TaskName "Kaseya Agent Watchdog"

    } catch {
        #Handle error
        Write-Host "Unable to create task."
        Write-Host $_.Exception.Message
    }
}

if (1 -eq $LogIt)
{
    $Pref = "SilentlyContinue"
    $DebugPreference = $Pref
    $VerbosePreference = $Pref
    $InformationPreference = $Pref
    Stop-Transcript
}