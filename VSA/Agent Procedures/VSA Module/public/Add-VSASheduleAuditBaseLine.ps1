function Add-VSASheduleAuditBaseLine
{
    <#
    .Synopsis
       Schedules a baseline audit.
    .DESCRIPTION
       Schedules a baseline audit for a single agent. A baseline audit shows the configuration of the system in its original state. Typically a baseline audit is performed when a system is first set up.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .EXAMPLE
       Add-VSASheduleAuditBaseLine  -AgentID 10001
    .EXAMPLE
       Add-VSASheduleAuditBaseLine  -AgentID 10001 -VSAConnection $connection
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

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/assetmgmt/audit/baseline/{0}/schedule', 
 
        [parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentID,

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
        [string] $Magnitude = '0'
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

            return $RuntimeParameterDictionary
        }
    }
    Begin {
    }

    Process {

        $URISuffix = $URISuffix -f $AgentID

        [string] $Times      = $PSBoundParameters.Times
        [string] $DaysOfWeek = $PSBoundParameters.DaysOfWeek
        [string] $DayOfMonth = $PSBoundParameters.DayOfMonth        

        [hashtable]$Recurrence = @{
            Repeat  = $Repeat
            EndAt = $EndAt
            EndOn = $EndOn
        }

        if ($Times)                 { $Recurrence.Add('Times', $Times) }
        if ($DaysOfWeek)            { $Recurrence.Add('DaysOfWeek', $DaysOfWeek) }
        if ($DayOfMonth)            { $Recurrence.Add('DayOfMonth', $DayOfMonth) }
        if ($SpecificDayOfMonth)    { $Recurrence.Add('SpecificDayOfMonth', $SpecificDayOfMonth) }
        if ($MonthOfYear)           { $Recurrence.Add('MonthOfYear', $MonthOfYear)}
        if ($EndAfterIntervalTimes) { $Recurrence.Add('EndAfterIntervalTimes', $EndAfterIntervalTimes) }
    
        [hashtable]$Distribution = @{
            Interval  = $Interval
            Magnitude = $Magnitude
        }

        [hashtable]$BodyHT = @{}
        
        if ( 0 -lt $($Recurrence.Count) )   { $BodyHT.Add('Recurrence', $Recurrence) }
        if ( 0 -lt $($Distribution.Count) ) { $BodyHT.Add('Distribution', $Distribution) }

        $Body = ConvertTo-Json $BodyHT

        $Body | Out-String | Write-Output

        [hashtable]$Params = @{
            URISuffix = $($URISuffix -f $AgentID)
            Method = 'PUT'
            Body = $Body
        }

        if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

        #return Update-VSAItems @Params
    }
}
Export-ModuleMember -Function Add-VSASheduleAuditBaseLine