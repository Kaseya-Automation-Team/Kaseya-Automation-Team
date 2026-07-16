function New-VSAAPScheduled {
    <#
    .Synopsis
       Adds new scheduled procedure
    .DESCRIPTION
       Adds new scheduled procedure to the specified agent machine.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AgentId
        Specifies numeric id of agent machine.
    .PARAMETER AgentProcedureId
        Specifies numeric id of agent procedure.
    .PARAMETER ScriptPrompts
        Specifies data used to fill fields prompted by procedure.
    .PARAMETER ServerTimeZone
        Specifies if procedure should be scheduled in server time zone.
    .PARAMETER SkipIfOffLine
        Specifies if procedure should NOT be executed if agent is offline at scheduled time.
    .PARAMETER PowerUpIfOffLine
        Specifies if machine should be powered up at scheduled time.
    .PARAMETER Repeat
        Specifies the recurrence interval: Never, Minutes, Hours, Days, Weeks, Months or Years.
        Any value other than 'Never' exposes the recurrence parameters below.
    .PARAMETER Times
        Specifies how many -Repeat intervals elapse between runs. Available when -Repeat is not 'Never'.
    .PARAMETER DaysOfWeek
        Specifies the day of the week to run on (Sunday..Saturday). Available when -Repeat is not 'Never'.
    .PARAMETER DayOfMonth
        Specifies the ordinal day of the month to run on (e.g. FirstMonday, LastWeekDay, LastDay).
        Available when -Repeat is not 'Never'.
    .PARAMETER MonthOfYear
        Specifies the month to run in (January..December). Available when -Repeat is not 'Never'.
    .PARAMETER SpecificDayOfMonth
        Specifies index of day in the month.
    .PARAMETER EndAt
        Specifies 15 minutes interval when procedure should end (24-hour HHMM, e.g. "1345"; no leading "T" - the server rejects a "T"-prefixed EndAt with HTTP 400).
    .PARAMETER EndOn
        Specifies date and time when recurrence should be ended.
    .PARAMETER EndAfterIntervalTimes
        Specifies if recurrence should end after a specific amount of executions.
    .PARAMETER Interval
        Specifies unit of measurement for interval of distribution window.
    .PARAMETER Magnitude
        Specifies numeric interval of distribution window.
    .PARAMETER StartOn
        Specifies date and time when procedure should be executed.
    .PARAMETER StartAt
        Specifies 15 minutes interval when procedure should be executed.
    .PARAMETER ExcludeFrom
        Specifies interval for exclusion of execution.
    .PARAMETER ExcludeTo
        Specifies interval for exclusion of execution.
    .PARAMETER AgentTime
        Specifies if agent procedure should be scheduled in time of agent.
    .EXAMPLE
       New-VSAAPScheduled -AgentId 2343322 -AgentProcedureId 1435 -Repeat "Never" -PowerUpIfOffLine -SkipIfOffLine -ScriptPrompts @(@{Caption="Please enter your username"; Name="username"; value="administrator"}) -StartOn "2021-09-30T11:20:00.000Z"
    .EXAMPLE
       New-VSAAPScheduled -AgentId 2343322 -AgentProcedureId 1435 -EndAt "1345" -EndOn "2021-10-30T12:00:00.000Z" -Repeat "Days" -Times 3 -AgentTime -ExcludeFrom "T1000" -ExcludeTo "T1200"
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       No output
    #>

    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is invoked centrally by Invoke-VSAWriteRequest, which receives this cmdlet''s $PSCmdlet via -Caller (module-wide pattern).')]
    param (
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = "api/v1.0/automation/agentprocs/{0}/{1}/schedule",

        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if ($_ -notmatch "^\d+$") {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentID,

        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if ($_ -notmatch "^\d+$") {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentProcedureId,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [array] $ScriptPrompts,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Never', 'Minutes', 'Hours', 'Days', 'Weeks', 'Months', 'Years')]
        [string] $Repeat = 'Never',

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if ($_ -notmatch "^\d+$") {
                throw "Non-numeric value"
            }
            return $true
        })]
        [int] $SpecificDayOfMonth,

        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string] $EndAt,

        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [datetime] $EndOn,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [int] $EndAfterIntervalTimes,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $Interval = 'Minutes',

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if ($_ -notmatch "^\d+$") {
                throw "Non-numeric value"
            }
            return $true
        })]
        [int] $Magnitude = 0,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [datetime] $StartOn,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $StartAt,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $ExcludeFrom,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $ExcludeTo,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [bool] $AgentTime = $false,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [bool] $ServerTimeZone = $false,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [bool] $SkipIfOffLine = $false,

        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [bool] $PowerUpIfOffLine = $false
    )

    DynamicParam {
        # New-VSARuntimeParameter is a private module helper (private/New-VSARuntimeParameter.ps1),
        # visible here because a DynamicParam block runs in module scope.
        if ($Repeat -ne 'Never') {
            $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

            $RuntimeParameterDictionary['Times'] = New-VSARuntimeParameter -Name 'Times' -Type ([int]) -Mandatory $false

            $daysOfWeek = @('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')
            $RuntimeParameterDictionary['DaysOfWeek'] = New-VSARuntimeParameter -Name 'DaysOfWeek' -Type ([string]) -ValidateSet $daysOfWeek -Mandatory $false

            $dayOfMonth = @(
                'FirstSunday', 'SecondSunday', 'ThirdSunday', 'FourthSunday', 'LastSunday',
                'FirstMonday', 'SecondMonday', 'ThirdMonday', 'FourthMonday', 'LastMonday',
                'FirstTuesday', 'SecondTuesday', 'ThirdTuesday', 'FourthTuesday', 'LastTuesday',
                'FirstWednesday', 'SecondWednesday', 'ThirdWednesday', 'FourthWednesday', 'LastWednesday',
                'FirstThursday', 'SecondThursday', 'ThirdThursday', 'FourthThursday', 'LastThursday',
                'FirstFriday', 'SecondFriday', 'ThirdFriday', 'FourthFriday', 'LastFriday',
                'FirstSaturday', 'SecondSaturday', 'ThirdSaturday', 'FourthSaturday', 'LastSaturday',
                'FirstWeekDay', 'SecondWeekDay', 'ThirdWeekDay', 'FourthWeekDay', 'LastWeekDay',
                'FirstWeekendDay', 'SecondWeekendDay', 'ThirdWeekendDay', 'FourthWeekendDay', 'LastWeekendDay',
                'FirstDay', 'SecondDay', 'ThirdDay', 'FourthDay', 'LastDay'
            )
            $RuntimeParameterDictionary['DayOfMonth'] = New-VSARuntimeParameter -Name 'DayOfMonth' -Type ([string]) -ValidateSet $dayOfMonth -Mandatory $false

            $monthsOfYear = @('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December')
            $RuntimeParameterDictionary['MonthOfYear'] = New-VSARuntimeParameter -Name 'MonthOfYear' -Type ([string]) -ValidateSet $monthsOfYear -Mandatory $false

            return $RuntimeParameterDictionary
        }
    }

    Begin {}

    Process {
        $Recurrence = @{
            Repeat                = $Repeat
            EndAt                 = $EndAt
            EndOn                 = $EndOn
            Times                 = $PSBoundParameters.Times
            DaysOfWeek            = $PSBoundParameters.DaysOfWeek
            DayOfMonth            = $PSBoundParameters.DayOfMonth
            MonthOfYear           = $PSBoundParameters.MonthOfYear
            EndAfterIntervalTimes = $EndAfterIntervalTimes
        }

        # F-35: the server rejects a body that sets BOTH DayOfMonth and SpecificDayOfMonth
        # ("Both DayOfMonth and SpecificDayOfMonth cannot be set"). SpecificDayOfMonth is a static
        # [int] parameter defaulting to 0, so it was ALWAYS serialized (as 0) and collided with any
        # DayOfMonth selection -> every monthly by-weekday schedule (e.g. -DayOfMonth LastDay) failed
        # with HTTP 400. Send it only when the caller actually supplied it (they are mutually exclusive).
        if ($PSBoundParameters.ContainsKey('SpecificDayOfMonth')) {
            $Recurrence.SpecificDayOfMonth = $SpecificDayOfMonth
        }

        $Distribution = @{
            Interval  = $Interval
            Magnitude = $Magnitude
        }

        $URISuffix = $URISuffix -f $AgentId, $AgentProcedureId

        $BodyHT = @{
            ServerTimeZone   = $ServerTimeZone
            SkipIfOffline    = $SkipIfOffLine
            PowerUpIfOffLine = $PowerUpIfOffLine
            Recurrence       = $Recurrence
            Distribution     = $Distribution
            SchedInAgentTime = $AgentTime
        }

        if ($StartOn)         { $BodyHT.Start = @{ StartOn = $StartOn; StartAt = $StartAt } }
        if ($ScriptPrompts)   { $BodyHT.ScriptPrompts = @($ScriptPrompts) }
        if ($ExcludeFrom -and $ExcludeTo) { $BodyHT.Exclusion = @{ From = $ExcludeFrom; To = $ExcludeTo } }

        return Invoke-VSAWriteRequest -Body ($BodyHT | ConvertTo-Json) -Method 'PUT' -URISuffix ($URISuffix) -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
New-Alias -Name Add-VSAScheduledAP -Value New-VSAAPScheduled
Export-ModuleMember -Function New-VSAAPScheduled -Alias Add-VSAScheduledAP
