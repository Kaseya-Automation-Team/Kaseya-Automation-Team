function Set-VSAPatchIgnore
{
    <#
    .Synopsis
       Sets the Ignore setting for missing patches for an agent machine.
    .DESCRIPTION
       Sets the Ignore setting for missing patches for an agent machine.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AgentId
        Specifies numeric id of agent machine
     .PARAMETER PatchIds
        Specifies array of patch ids or single id
    .PARAMETER ServerTimeZone
        Specifies if procedure should be scheduled in server time zone
    .PARAMETER SkipIfOffLine
        Specifies if procedure should NOT be executed if agent is offline at scheduled time     
    .PARAMETER PowerUpIfOffLine
        Specifies if machine should be powered up at scheduled time        
    .PARAMETER SpecificDayOfMonth
        Specifies index of day in the month       
    .PARAMETER EndAt
        Specifies 15 minutes interval when procedure should end
    .PARAMETER EndOn
        Specifies date and time when recurrence should be ended   
    .PARAMETER EndAfterIntervalTimes
        Specifies if recurrence should end after specific amount of executions                  
    .PARAMETER Interval
        Specifies unit of measurement for interval of distribution window
    .PARAMETER Magniture
        Specifies numeric interval of distribution window
    .PARAMETER StartOn
    Specifies date and time when procedure should be executed
    .PARAMETER StartAt
    Specifies 15 minutes interval when procedure should be executed
    .PARAMETER ExcludeFrom
    Specifies interval for exclusion of execution
    .PARAMETER ExcludeTo
    Specifies interval for exclusion of execution
    .PARAMETER AgentTime
    Specifies if agent procedure should be scheduled in time of agent
    .EXAMPLE
       Set-VSAPatchIgnore -AgentId 2343322 -Repeat "Never" -PowerUpIfOffLine -SkipIfOffLine -PatchIds 189, 190, 220 -EndOn "2021-09-30T11:20:00.000Z" -EndAt "2021-09-30T11:20:00.000Z"
    .EXAMPLE
       Set-VSAPatchIgnore -AgentId 2343322 -PatchIds 189, 190, 220 -EndAt "T1345" -EndOn "2021-10-30T12:00:00.000Z" -Repeat "Days" -Times 3 -AgentTime -ExcludeFrom "T1000" -ExcludeTo "T1200"
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Success or failure
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/assetmgmt/patch/{0}/setignore",

        [parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentID,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()] 
        [string[]] $PatchIds,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [switch] $ServerTimeZone,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [switch] $SkipIfOffLine,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [switch] $PowerUpIfOffLine,

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Never', 'Minutes', 'Hours', 'Days', 'Weeks', 'Months', 'Years')]
        [string] $Repeat = 'Never',

        [Parameter(Mandatory = $false)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $SpecificDayOfMonth,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string] $EndAt,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string] $EndOn,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [string] $EndAfterIntervalTimes,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [string] $Interval = 'Minutes',

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $Magnitude = '0',

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [string] $StartOn,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [string] $StartAt,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [string] $ExcludeFrom,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [string] $ExcludeTo,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [switch] $AgentTime
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
    }
    Begin {
    }

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
New-Alias -Name Add-VSAPatchIgnore -Value Set-VSAPatchIgnore
Export-ModuleMember -Function Set-VSAPatchIgnore -Alias Add-VSAPatchIgnore