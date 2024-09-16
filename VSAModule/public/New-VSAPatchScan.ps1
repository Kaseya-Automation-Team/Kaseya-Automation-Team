function New-VSAPatchScan
{
    <#
    .Synopsis
       Schedules a scan on an agent machine for missing patches.
    .DESCRIPTION
       Schedules a scan on an agent machine for missing patches.
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
       New-VSAPatchScan -AgentId 2343322 -Repeat "Never" -PowerUpIfOffLine -SkipIfOffLine -PatchIds 189, 190, 220 -EndOn "2021-09-30T11:20:00.000Z" -EndAt "2021-09-30T11:20:00.000Z"
    .EXAMPLE
       New-VSAPatchScan -AgentId 2343322 -PatchIds 189, 190, 220 -EndAt "T1345" -EndOn "2021-10-30T12:00:00.000Z" -Repeat "Days" -Times 3 -AgentTime -ExcludeFrom "T1000" -ExcludeTo "T1200"
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
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = "api/v1.0/assetmgmt/patch/{0}/schedule",

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
        [ValidateNotNullOrEmpty()] 
        [array] $PatchIds,

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

        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [string] $EndAt,

        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [string] $EndOn,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [string] $EndAfterIntervalTimes,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [string] $Interval = 'Minutes',

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $Magnitude = '0',

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [string] $StartOn,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [string] $StartAt,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [string] $ExcludeFrom,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [string] $ExcludeTo,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [switch] $AgentTime,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [switch] $ServerTimeZone,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [switch] $SkipIfOffLine,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [switch] $PowerUpIfOffLine
        
)
   
    DynamicParam {
        if ( 'Never' -notmatch $Repeat ) {

            $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $false
            $AttributeCollection.Add($ParameterAttribute)
            $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter('Times', [int], $AttributeCollection)
            $RuntimeParameterDictionary.Add('Times', $RuntimeParameter)


            $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $false
            $AttributeCollection.Add($ParameterAttribute)
            [string[]] $ValidateSet = @('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
            $AttributeCollection.Add($ValidateSetAttribute)
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter('DaysOfWeek', [string], $AttributeCollection)
            $RuntimeParameterDictionary.Add('DaysOfWeek', $RuntimeParameter)

            $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $false
            $AttributeCollection.Add($ParameterAttribute)
            [string[]] $ValidateSet = @('FirstSunday', 'SecondSunday', 'ThirdSunday', 'FourthSunday', 'LastSunday', 'FirstMonday', 'SecondMonday', 'ThirdMonday', 'FourthMonday', 'LastMonday', 'FirstTuesday', 'SecondTuesday', 'ThirdTuesday', 'FourthTuesday', 'LastTuesday', 'FirstWednesday', 'SecondWednesday', 'ThirdWednesday', 'FourthWednesday', 'LastWednesday', 'FirstThursday', 'SecondThursday', 'ThirdThursday', 'FourthThursday', 'LastThursday', 'FirstFriday', 'SecondFriday', 'ThirdFriday', 'FourthFriday', 'LastFriday', 'FirstSaturday', 'SecondSaturday', 'ThirdSaturday', 'FourthSaturday', 'LastSaturday', 'FirstWeekDay', 'SecondWeekDay', 'ThirdWeekDay', 'FourthWeekDay', 'LastWeekDay', 'FirstWeekendDay', 'SecondWeekendDay', 'ThirdWeekendDay', 'FourthWeekendDay', 'LastWeekendDay', 'FirstDay', 'SecondDay', 'ThirdDay', 'FourthDay', 'LastDay')
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
            $AttributeCollection.Add($ValidateSetAttribute)
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter('DayOfMonth', [string], $AttributeCollection)
            $RuntimeParameterDictionary.Add('DayOfMonth', $RuntimeParameter)

            $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $false
            $AttributeCollection.Add($ParameterAttribute)
            [string[]] $ValidateSet = @('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December')
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
            $AttributeCollection.Add($ValidateSetAttribute)
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter('MonthOfYear', [string], $AttributeCollection)
            $RuntimeParameterDictionary.Add('MonthOfYear', $RuntimeParameter)

            return $RuntimeParameterDictionary
        }
    }
    Begin {
    }

    Process {    
   
        [string] $Times       = $PSBoundParameters.Times
        [string] $DaysOfWeek  = $PSBoundParameters.DaysOfWeek
        [string] $DayOfMonth  = $PSBoundParameters.DayOfMonth
        [string] $MonthOfYear = $PSBoundParameters.MonthOfYear

        [hashtable]$Recurrence = @{
            Repeat                = $Repeat
            EndAt                 = $EndAt
            EndOn                 = $EndOn
            Times                 = $Times
            DaysOfWeek            = $DaysOfWeek
            DayOfMonth            = $DayOfMonth
            SpecificDayOfMonth    = $SpecificDayOfMonth
            MonthOfYear           = $MonthOfYear
            EndAfterIntervalTimes = $EndAfterIntervalTimes
        }
        foreach ( $key in $Recurrence.Keys.Clone() ) {
            if ( -not $Recurrence[$key] )  { $Recurrence.Remove($key) }
        }
        
        [hashtable]$Distribution = @{
            Interval  = $Interval
            Magnitude = $Magnitude
        }

        [hashtable]$Start =@{
            StartOn = $StartOn
            StartAt = $StartAt
        }

        [hashtable]$Exclusion =@{
            From = $ExcludeFrom
            To   = $ExcludeTo
        }

        $BodyHT = @{"ServerTimeZone"=$ServerTimeZone.ToBool(); "SkipIfOffline"=$SkipIfOffLine.ToBool(); "PowerUpIfOffLine"=$PowerUpIfOffLine.ToBool(); "Recurrence"=$Recurrence; "Distribution"=$Distribution; "SchedInAgentTime"=$AgentTime.ToBool()}

        if ( -not [string]::IsNullOrEmpty($StartOn) )    {  $BodyHT.Add('Start', $Start) }
        if ( -not [string]::IsNullOrEmpty($PatchIds) )   {  $BodyHT.Add('PatchIds', $PatchIds) }
        if ( (-not [string]::IsNullOrEmpty($ExcludeFrom)) -and (-not [string]::IsNullOrEmpty($ExcludeTo)))  {  $BodyHT.Add('Exclusion', $Exclusion) }

        [hashtable]$Params =@{
            URISuffix = $($URISuffix -f $AgentId)
            Method    = 'PUT'
            Body      = $($BodyHT | ConvertTo-Json -Compress)
        }

        if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

        return Invoke-VSARestMethod @Params
    }

}

New-Alias -Name Add-VSAPatchScan -Value New-VSAPatchScan
Export-ModuleMember -Function New-VSAPatchScan -Alias Add-VSAPatchScan