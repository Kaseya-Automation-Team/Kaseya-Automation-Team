function Set-VSAAuditSchedule
{
    <#
    .Synopsis
       Schedules a latest audit.
    .DESCRIPTION
       Schedules a latest audit for a single agent. The latest audit shows the configuration of the system as of the last audit. Once per day is recommended.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER Repeat
        RecurrenceOptions
    .PARAMETER Times
        RecurrenceOptions
    .PARAMETER DaysOfWeek
        RecurrenceOptions
    .PARAMETER DayOfMonth
        RecurrenceOptions
    .PARAMETER SpecificDayOfMonth
        RecurrenceOptions
    .PARAMETER MonthOfYear
        RecurrenceOptions
    .PARAMETER EndAt
        RecurrenceOptions
    .PARAMETER EndOn
        RecurrenceOptions
    .PARAMETER EndAfterIntervalTimes
        RecurrenceOptions
    .PARAMETER Interval
        DistributionWindow
    .PARAMETER Magnitude
        DistributionWindow
    .PARAMETER StartOn
        StartOptions
    .PARAMETER StartAt
        StartOptions
    .PARAMETER ExcludeFrom
        ExclusionWindow
    .PARAMETER ExcludeTo
        ExclusionWindow
    .EXAMPLE
       Set-VSAAuditSchedule -AgentID 10001 -Repeat Never
    .EXAMPLE
       Set-VSAAuditSchedule -AgentID 10001 -Repeat Never -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if start of baseline audit was successful.
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/assetmgmt/audit/latest/{0}/schedule', 
 
        [parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentID,

        [parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Never', 'Minutes', 'Hours', 'Days', 'Weeks', 'Months', 'Years')]
        [string] $Repeat = 'Never',

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $Interval = 'Minutes',

        [Parameter(Mandatory = $false)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $Magnitude = '0',

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $StartOn,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $StartAt,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $ExcludeFrom,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $ExcludeTo
    )
    DynamicParam {
        if ( 'Never' -notmatch $Repeat ) {
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

                $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($Name, $Type, $AttributesCollection)
                return $RuntimeParameter
            }

            $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

            $RuntimeParameterDictionary.Add('Times', (Create-Parameter -Name 'Times' -Type [int]))
            $RuntimeParameterDictionary.Add('DaysOfWeek', (Create-Parameter -Name 'DaysOfWeek' -Type [string] -ValidateSet @('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')))
            $RuntimeParameterDictionary.Add('SpecificDayOfMonth', (Create-Parameter -Name 'SpecificDayOfMonth' -Type [int]))
            $RuntimeParameterDictionary.Add('EndAfterIntervalTimes', (Create-Parameter -Name 'EndAfterIntervalTimes' -Type [int]))
            $RuntimeParameterDictionary.Add('DayOfMonth', (Create-Parameter -Name 'DayOfMonth' -Type [string] -ValidateSet @('FirstSunday', 'SecondSunday', 'ThirdSunday', 'FourthSunday', 'LastSunday', 'FirstMonday', 'SecondMonday', 'ThirdMonday', 'FourthMonday', 'LastMonday', 'FirstTuesday', 'SecondTuesday', 'ThirdTuesday', 'FourthTuesday', 'LastTuesday', 'FirstWednesday', 'SecondWednesday', 'ThirdWednesday', 'FourthWednesday', 'LastWednesday', 'FirstThursday', 'SecondThursday', 'ThirdThursday', 'FourthThursday', 'LastThursday', 'FirstFriday', 'SecondFriday', 'ThirdFriday', 'FourthFriday', 'LastFriday', 'FirstSaturday', 'SecondSaturday', 'ThirdSaturday', 'FourthSaturday', 'LastSaturday', 'FirstWeekDay', 'SecondWeekDay', 'ThirdWeekDay', 'FourthWeekDay', 'LastWeekDay', 'FirstWeekendDay', 'SecondWeekendDay', 'ThirdWeekendDay', 'FourthWeekendDay', 'LastWeekendDay', 'FirstDay', 'SecondDay', 'ThirdDay', 'FourthDay', 'LastDay''FirstSunday', 'SecondSunday', 'ThirdSunday', 'FourthSunday', 'LastSunday', 'FirstMonday', 'SecondMonday', 'ThirdMonday', 'FourthMonday', 'LastMonday', 'FirstTuesday', 'SecondTuesday', 'ThirdTuesday', 'FourthTuesday', 'LastTuesday', 'FirstWednesday', 'SecondWednesday', 'ThirdWednesday', 'FourthWednesday', 'LastWednesday', 'FirstThursday', 'SecondThursday', 'ThirdThursday', 'FourthThursday', 'LastThursday', 'FirstFriday', 'SecondFriday', 'ThirdFriday', 'FourthFriday', 'LastFriday', 'FirstSaturday', 'SecondSaturday', 'ThirdSaturday', 'FourthSaturday', 'LastSaturday', 'FirstWeekDay', 'SecondWeekDay', 'ThirdWeekDay', 'FourthWeekDay', 'LastWeekDay', 'FirstWeekendDay', 'SecondWeekendDay', 'ThirdWeekendDay', 'FourthWeekendDay', 'LastWeekendDay', 'FirstDay', 'SecondDay', 'ThirdDay', 'FourthDay', 'LastDay')))
            $RuntimeParameterDictionary.Add('MonthOfYear', (Create-Parameter -Name 'MonthOfYear' -Type [string] -ValidateSet @('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December')))
            $RuntimeParameterDictionary.Add('EndAt', (Create-Parameter -Name 'EndAt' -Type [string]))
            $RuntimeParameterDictionary.Add('EndOn', (Create-Parameter -Name 'EndOn' -Type [string]))

            return $RuntimeParameterDictionary
        }
    }# DynamicParam

    Begin {
        if ( ( $Repeat -match 'Days' ) -and `
            -not ` (
            $PSBoundParameters.DaysOfWeek -or `
            $PSBoundParameters.DayOfMonth -or `
            $PSBoundParameters.SpecificDayOfMonth ) ) {
            Write-Error "Repeat set to $Repeat, but no details specified" -ErrorAction Stop
        }
        if ( ( $Repeat -match 'Months') -and `
            -not ` ( $PSBoundParameters.MonthOfYear) ) {
            Write-Error "Repeat set to $Repeat, but no details specified" -ErrorAction Stop
        }

    }# Begin

    Process {
        $Recurrence = [PSCustomObject]@{
            Repeat                 = $Repeat
            Times                  = $PSBoundParameters.Times
            DaysOfWeek             = $PSBoundParameters.DaysOfWeek
            DayOfMonth             = $PSBoundParameters.DayOfMonth
            SpecificDayOfMonth     = $PSBoundParameters.SpecificDayOfMonth
            MonthOfYear            = $PSBoundParameters.MonthOfYear
            EndAfterIntervalTimes  = $PSBoundParameters.EndAfterIntervalTimes
            EndAt                  = $PSBoundParameters.EndAt
            EndOn                  = $PSBoundParameters.EndOn
        } | Where-Object { $_.Value }

        $Distribution = [PSCustomObject]@{
            Interval  = $Interval
            Magnitude = $Magnitude
        } | Where-Object { $_.Value }

        $Start = [PSCustomObject]@{
            StartOn = $StartOn
            StartAt = $StartAt
        } | Where-Object { $_.Value }

        $Exclusion = [PSCustomObject]@{
            ExcludeFrom = $ExcludeFrom
            ExcludeTo   = $ExcludeTo
        } | Where-Object { $_.Value }

        $BodyHT = [PSCustomObject]@{}
        
        if ($Recurrence) { $BodyHT.Recurrence = $Recurrence }
        if ($Distribution) { $BodyHT.Distribution = $Distribution }
        if ($Start) { $BodyHT.Start = $Start }
        if ($Exclusion) { $BodyHT.Exclusion = $Exclusion }

        $Body = ConvertTo-Json $BodyHT

        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
            Write-Debug "New-VSAScheduleAuditBaseLine. $($Body | Out-String)"
        }

        $Params = @{
            URISuffix = $URISuffix -f $AgentID
            Method    = 'PUT'
            Body      = $Body
        }

        if ($VSAConnection) { $Params.VSAConnection = $VSAConnection }

        return Invoke-VSARestMethod @Params
    }# Process
}
New-Alias -Name Add-VSAScheduleAuditLatest -Value Set-VSAAuditSchedule
Export-ModuleMember -Function Set-VSAAuditSchedule -Alias Add-VSAScheduleAuditLatest