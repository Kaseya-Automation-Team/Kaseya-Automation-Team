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
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $AgentId,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $AgentProcedureId,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$false)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Caption,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$false)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Name,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$false)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Value,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [switch] $ServerTimeZone,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [switch] $SkipIfOffLine,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [switch] $PowerUpIfOffLine,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [string] $Repeat = "Never",
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [int] $Times,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [string] $DaysOfWeek,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [string] $DayOfMonth,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [string] $SpecificDayOfMonth,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [string] $MonthOfYear,
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
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $false)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [int] $Magnitude = 0

        
)
    if ($Caption) {

    [hashtable]$ScriptPrompts = @{
        Caption  = $Caption
        Name = $Name
        Value = $Value
    }

    }

    if (($Times -or $DaysOfWeek -or $DayOfMonth -or $SpecificDayOfMonth -or $MonthOfYear) -and ($Repeat -eq 'Never')) {
        throw "Number of times and parameter of specific day can NOT be used if Repeat parameter is set to Never"
    }

    
    [hashtable]$Recurrence = @{
        Repeat  = $Repeat
        EndAt = $EndAt
        EndOn = $EndOn
    }
    
    [hashtable]$Distribution = @{
        Interval  = $Interval
        Magnitude = $Magnitude
    }

    if ($Times) {
        $Recurrence.Add('Times', $Times)
    }

    if ($DaysOfWeek) {
        $Recurrence.Add('DaysOfWeek', $DaysOfWeek)
    }

    if ($DayOfMonth) {
        $Recurrence.Add('DayOfMonth', $DayOfMonth)
    }

    if ($SpecificDayOfMonth) {
        $Recurrence.Add('SpecificDayOfMonth', $SpecificDayOfMonth)
    }

    if ($MonthOfYear) {
        $Recurrence.Add('MonthOfYear', $MonthOfYear)
    }

    if ($EndAfterIntervalTimes) {
        $Recurrence.Add('EndAfterIntervalTimes', $EndAfterIntervalTimes)
    }


    $URISuffix = $URISuffix -f $AgentId, $AgentProcedureId
    
    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'PUT'
    }

	if ($Caption) {

        $Body = ConvertTo-Json @{"ServerTimeZone"=$ServerTimeZone.ToBool(); "SkipIfOffline"=$SkipIfOffLine.ToBool(); "PowerUpIfOffLine"=$PowerUpIfOffLine.ToBool(); "ScriptPrompts"=@($ScriptPrompts); "Recurrence"=$Recurrence; "Distribution"=$Distribution;}

    } else {
        $Body = ConvertTo-Json @{"ServerTimeZone"=$ServerTimeZone.ToBool(); "SkipIfOffline"=$SkipIfOffLine.ToBool(); "PowerUpIfOffLine"=$PowerUpIfOffLine.ToBool(); "Recurrence"=$Recurrence; "Distribution"=$Distribution;}
    }
	
    $Params.Add('Body', $Body)

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    Write-Host $Body

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Add-VSAScheduledAP