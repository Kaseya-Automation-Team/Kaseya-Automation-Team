function Add-VSAPatchIgnore
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
       Add-VSAPatchIgnore -AgentId 2343322 -Repeat "Never" -PowerUpIfOffLine -SkipIfOffLine -PatchIds 189, 190, 220 -EndOn "2021-09-30T11:20:00.000Z" -EndAt "2021-09-30T11:20:00.000Z"
    .EXAMPLE
       Add-VSAPatchIgnore -AgentId 2343322 -PatchIds 189, 190, 220 -EndAt "T1345" -EndOn "2021-10-30T12:00:00.000Z" -Repeat "Days" -Times 3 -AgentTime -ExcludeFrom "T1000" -ExcludeTo "T1200"
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Success or failure
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
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [array] $PatchIds,
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
        $URISuffix = $URISuffix -f $AgentId
    
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

        if ( -not [string]::IsNullOrEmpty($StartOn) )         {  $BodyHT.Add('Start', $Start) }
        if ( -not [string]::IsNullOrEmpty($PatchIds) )   {  $BodyHT.Add('PatchIds', $PatchIds) }
        if ( (-not [string]::IsNullOrEmpty($ExcludeFrom)) -and (-not [string]::IsNullOrEmpty($ExcludeTo)))  {  $BodyHT.Add('Exclusion', $Exclusion) }

        $Body = $BodyHT | ConvertTo-Json
	
        $Params.Add('Body', $Body)

        if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

        Write-Host $Body
        
        return Update-VSAItems @Params
    }

}


Export-ModuleMember -Function Add-VSAPatchIgnore