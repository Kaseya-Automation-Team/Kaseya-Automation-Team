function Add-VSAScheduledAP
{
    <#
    .Synopsis
       Adds new user role
    .DESCRIPTION
       Adds new user role in VSA with specified role type ids
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER RoleName
        Specifies name of the role
    .PARAMETER RoleTypeIds
        Specifies array of role type ids
    .EXAMPLE
       Add-VSAScheduledTask -RoleName "Remote desktop" -RoleTypeIds 4, 6, 100, 101
    .EXAMPLE
       Add-VSAScheduledTask -VSAConnection $connection -RoleName "Remote desktop" -RoleTypeIds 4, 6, 100, 101
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       No output
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NonPersistent')]
        [VSAConnection] $VSAConnection,
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'NonPersistent')]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'Persistent')]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/automation/agentprocs/{0}/{1}/schedule",
        [parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentID,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $AgentProcedureId,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$false)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [array]$ScriptPrompts,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [switch] $ServerTimeZone,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [switch] $SkipIfOffLine,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
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
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $true)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $true)]
        [string] $EndAt,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $true)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $true)]
        [string] $EndOn,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [string] $EndAfterIntervalTimes,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [string] $Interval = 'Minutes',
        [Parameter(Mandatory = $false)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $Magnitude = '0',
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [string] $StartOn,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [string] $StartAt,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [string] $ExcludeFrom,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [string] $ExcludeTo,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [switch] $AgentTime

        
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
            Repeat  = $Repeat
            EndAt = $EndAt
            EndOn = $EndOn
        }
        
        if ( -not [string]::IsNullOrEmpty($Times) )                 { $Recurrence.Add('Times', $Times) }
        if ( -not [string]::IsNullOrEmpty($DaysOfWeek) )            { $Recurrence.Add('DaysOfWeek', $DaysOfWeek) }
        if ( -not [string]::IsNullOrEmpty($DayOfMonth) )            { $Recurrence.Add('DayOfMonth', $DayOfMonth) }
        if ( -not [string]::IsNullOrEmpty($SpecificDayOfMonth) )    { $Recurrence.Add('SpecificDayOfMonth', $SpecificDayOfMonth) }
        if ( -not [string]::IsNullOrEmpty($MonthOfYear) )           { $Recurrence.Add('MonthOfYear', $MonthOfYear)}
        if ( -not [string]::IsNullOrEmpty($EndAfterIntervalTimes) ) { $Recurrence.Add('EndAfterIntervalTimes', $EndAfterIntervalTimes) }
    
        [hashtable]$Distribution = @{
            Interval  = $Interval
            Magnitude = $Magnitude
        }
        $URISuffix = $URISuffix -f $AgentId, $AgentProcedureId
    
        [hashtable]$Params =@{
            URISuffix = $URISuffix
            Method = 'PUT'
        }

        [hashtable]$Start =@{
            StartOn = $StartOn
            StartAt = $StartAt
        }

        [hashtable]$Exclusion =@{
            From = $ExcludeFrom
            To = $ExcludeTo
        }
        
        [hashtable]$BodyHT = @{}

        $BodyHT = @{"ServerTimeZone"=$ServerTimeZone.ToBool(); "SkipIfOffline"=$SkipIfOffLine.ToBool(); "PowerUpIfOffLine"=$PowerUpIfOffLine.ToBool(); "Recurrence"=$Recurrence; "Distribution"=$Distribution; "SchedInAgentTime"=$AgentTime.ToBool()}

        if ( -not [string]::IsNullOrEmpty($StartOn) )           {  $BodyHT.Add('Start', $Start) }
        if ( -not [string]::IsNullOrEmpty($ScriptPrompts) )           {  $BodyHT.Add('ScriptPrompts', @($ScriptPrompts)) }
        if ( (-not [string]::IsNullOrEmpty($ExcludeFrom)) -and (-not [string]::IsNullOrEmpty($ExcludeTo)))           {  $BodyHT.Add('Exclusion', $Exclusion) }

        $Body = $BodyHT | ConvertTo-Json
	
        $Params.Add('Body', $Body)

        if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

        Write-Host $Body

        return Update-VSAItems @Params
    }

}


Export-ModuleMember -Function Add-VSAScheduledAP