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
    .PARAMETER SpecificDayOfMonth
        Specifies index of day in the month.
    .PARAMETER EndAt
        Specifies 15 minutes interval when procedure should end.
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
       New-VSAAPScheduled -AgentId 2343322 -AgentProcedureId 1435 -EndAt "T1345" -EndOn "2021-10-30T12:00:00.000Z" -Repeat "Days" -Times 3 -AgentTime -ExcludeFrom "T1000" -ExcludeTo "T1200"
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       No output
    .NOTES
        Version 1.0.0
    #>
    
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = "api/v1.0/automation/agentprocs/{0}/{1}/schedule",

        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if ($_ -notmatch "^\d+$") {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [int] $AgentID,

        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [int] $AgentProcedureId,

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
        function Create-Parameter {
            param (
                [string] $Name,
                [Type] $Type,
                [string[]] $ValidateSet = $null,
                [bool] $Mandatory = $false
            )

            $AttributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $Mandatory
            $AttributesCollection.Add($ParameterAttribute)
        
            if ($ValidateSet) {
                $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
                $AttributesCollection.Add($ValidateSetAttribute)
            }

            return New-Object System.Management.Automation.RuntimeDefinedParameter($Name, $Type, $AttributesCollection)
        }

        if ($Repeat -ne 'Never') {
            $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        
            $RuntimeParameterDictionary['Times'] = Create-Parameter -Name 'Times' -Type [int] -Mandatory $false

            $daysOfWeek = @('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')
            $RuntimeParameterDictionary['DaysOfWeek'] = Create-Parameter -Name 'DaysOfWeek' -Type [string] -ValidateSet $daysOfWeek -Mandatory $false

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
            $RuntimeParameterDictionary['DayOfMonth'] = Create-Parameter -Name 'DayOfMonth' -Type [string] -ValidateSet $dayOfMonth -Mandatory $false

            $monthsOfYear = @('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December')
            $RuntimeParameterDictionary['MonthOfYear'] = Create-Parameter -Name 'MonthOfYear' -Type [string] -ValidateSet $monthsOfYear -Mandatory $false

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
            SpecificDayOfMonth    = $SpecificDayOfMonth
            MonthOfYear           = $PSBoundParameters.MonthOfYear
            EndAfterIntervalTimes = $EndAfterIntervalTimes
        }

        $Distribution = @{
            Interval  = $Interval
            Magnitude = $Magnitude
        }

        $URISuffix = $URISuffix -f $AgentId, $AgentProcedureId

        $Params = @{
            URISuffix     = $URISuffix
            Method        = 'PUT'
            Body          = @{}
        }

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

        $Params.Body = $BodyHT | ConvertTo-Json

        if ($VSAConnection) { $Params.VSAConnection = $VSAConnection }

        return Invoke-VSARestMethod @Params
    }
}
New-Alias -Name Add-VSAScheduledAP -Value New-VSAAPScheduled
Export-ModuleMember -Function New-VSAAPScheduled -Alias Add-VSAScheduledAP
