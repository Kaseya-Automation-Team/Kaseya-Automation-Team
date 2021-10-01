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

        [parameter(Mandatory = $true,
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
        [string] $Times,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $EndOn,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $EndAt,

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

            $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

            $AttributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $false
            $AttributesCollection.Add($ParameterAttribute)
            [string[]] $ValidateSet = @('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
            $AttributesCollection.Add($ValidateSetAttribute)
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter('DaysOfWeek', [string], $AttributesCollection)
            $RuntimeParameterDictionary.Add('DaysOfWeek', $RuntimeParameter)

            $AttributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $false
            $AttributesCollection.Add($ParameterAttribute)
            
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter('SpecificDayOfMonth', [int], $AttributesCollection)
            $RuntimeParameterDictionary.Add('SpecificDayOfMonth', $RuntimeParameter)

            $AttributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $false
            $AttributesCollection.Add($ParameterAttribute)
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter('EndAfterIntervalTimes', [int], $AttributesCollection)
            $RuntimeParameterDictionary.Add('EndAfterIntervalTimes', $RuntimeParameter)

            $AttributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $false
            $AttributesCollection.Add($ParameterAttribute)
            [string[]] $ValidateSet = @('FirstSunday', 'SecondSunday', 'ThirdSunday', 'FourthSunday', 'LastSunday', 'FirstMonday', 'SecondMonday', 'ThirdMonday', 'FourthMonday', 'LastMonday', 'FirstTuesday', 'SecondTuesday', 'ThirdTuesday', 'FourthTuesday', 'LastTuesday', 'FirstWednesday', 'SecondWednesday', 'ThirdWednesday', 'FourthWednesday', 'LastWednesday', 'FirstThursday', 'SecondThursday', 'ThirdThursday', 'FourthThursday', 'LastThursday', 'FirstFriday', 'SecondFriday', 'ThirdFriday', 'FourthFriday', 'LastFriday', 'FirstSaturday', 'SecondSaturday', 'ThirdSaturday', 'FourthSaturday', 'LastSaturday', 'FirstWeekDay', 'SecondWeekDay', 'ThirdWeekDay', 'FourthWeekDay', 'LastWeekDay', 'FirstWeekendDay', 'SecondWeekendDay', 'ThirdWeekendDay', 'FourthWeekendDay', 'LastWeekendDay', 'FirstDay', 'SecondDay', 'ThirdDay', 'FourthDay', 'LastDay')
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
            $AttributesCollection.Add($ValidateSetAttribute)
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter('DayOfMonth', [string], $AttributesCollection)
            $RuntimeParameterDictionary.Add('DayOfMonth', $RuntimeParameter)
            
            $AttributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $false
            $AttributesCollection.Add($ParameterAttribute)
            [string[]] $ValidateSet = @('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December')
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
            $AttributesCollection.Add($ValidateSetAttribute)
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter('MonthOfYear', [string], $AttributesCollection)
            $RuntimeParameterDictionary.Add('MonthOfYear', $RuntimeParameter)

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
        [string] $DaysOfWeek            = $PSBoundParameters.DaysOfWeek
        [string] $DayOfMonth            = $PSBoundParameters.DayOfMonth
        [string] $MonthOfYear           = $PSBoundParameters.MonthOfYear
        [string] $EndAfterIntervalTimes = $PSBoundParameters.EndAfterIntervalTimes

        [hashtable]  $Recurrence = @{
            Repeat = $Repeat
            EndAt  = $EndAt
            EndOn  = $EndOn
        }

        if ( -not [string]::IsNullOrEmpty($Times) )                 { $Recurrence.Add('Times', [int]$Times ) }
        if ( -not [string]::IsNullOrEmpty($DaysOfWeek) )            { $Recurrence.Add('DaysOfWeek', $DaysOfWeek) }
        if ( -not [string]::IsNullOrEmpty($DayOfMonth) )            { $Recurrence.Add('DayOfMonth', $DayOfMonth) }
        if ( -not [string]::IsNullOrEmpty($SpecificDayOfMonth) )    { $Recurrence.Add('SpecificDayOfMonth', $SpecificDayOfMonth) }
        if ( -not [string]::IsNullOrEmpty($MonthOfYear) )           { $Recurrence.Add('MonthOfYear', $MonthOfYear)}
        if ( -not [string]::IsNullOrEmpty($EndAfterIntervalTimes) ) { $Recurrence.Add('EndAfterIntervalTimes', $EndAfterIntervalTimes) }

        [hashtable]$Distribution = @{}
        if ( -not [string]::IsNullOrEmpty($Interval) )              { $Distribution.Add('Interval', $Interval) }
        if ( -not [string]::IsNullOrEmpty($Magnitude) )             { $Distribution.Add('Magnitude', $Magnitude) }

        [hashtable]$Start =@{}
        if ( -not [string]::IsNullOrEmpty($StartOn) )               { $Start.Add('StartOn', $StartOn) }
        if ( -not [string]::IsNullOrEmpty($StartAt) )               { $Start.Add('StartAt', $StartAt) }

        [hashtable]$Exclusion =@{}
        if ( -not [string]::IsNullOrEmpty($ExcludeFrom) )           { $Exclusion.Add('ExcludeFrom', $ExcludeFrom) }
        if ( -not [string]::IsNullOrEmpty($ExcludeTo) )             { $Exclusion.Add('ExcludeTo', $ExcludeTo) }

        [hashtable]$BodyHT = @{}
        
        if ( 0 -lt $($Recurrence.Count) )   { $BodyHT.Add('Recurrence', $Recurrence) }
        if ( 0 -lt $($Distribution.Count) ) { $BodyHT.Add('Distribution', $Distribution) }
        if ( 0 -lt $($Start.Count) )        { $BodyHT.Add('Start', $Start) }
        if ( 0 -lt $($Exclusion.Count) )    { $BodyHT.Add('Exclusion', $Exclusion) }

        $Body = ConvertTo-Json $BodyHT

        $Body | Out-String | Write-Output

        [hashtable]$Params = @{
            URISuffix = $($URISuffix -f $AgentID)
            Method = 'PUT'
            Body = $Body
        }

        if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

        #return Update-VSAItems @Params
    }# Process
}
Export-ModuleMember -Function Add-VSASheduleAuditBaseLine