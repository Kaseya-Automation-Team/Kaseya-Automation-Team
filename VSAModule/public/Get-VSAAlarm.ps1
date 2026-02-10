function Get-VSAAlarm
{
    <#
    .Synopsis
       Returns VSA alarms
    .DESCRIPTION
       Returns alarms existing in VSA.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AlarmId
        Specifies id of a single alarm.
    .PARAMETER AllRecords
        Specifies if all alarms should be returned in the list or only new alarms are listed since the last time the alarm list was requested by the user's session
    .PARAMETER Filter
        Specifies REST API Filter.
    .PARAMETER Paging
        Specifies REST API Paging.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .EXAMPLE
       Get-VSAAlarm -AllRecords
    .EXAMPLE
       Get-VSAAlarm -AlarmId 138
    .EXAMPLE
       Get-VSAAlarm -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Array of custom objects that represent VSA alarms or details of single alarm
    #>

    [CmdletBinding(DefaultParameterSetName='All')]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'All')]
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ById')]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ParameterSetName = 'All')]
        [parameter(DontShow, Mandatory=$false,
            ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/assetmgmt/alarms/{0}",

        [Parameter(Mandatory = $false,
            ParameterSetName = 'ById')]
        [ValidateScript({
            if( -not [string]::IsNullOrEmpty($_) -and $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AlarmId,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'All')]
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'All')]
        [ValidateNotNullOrEmpty()] 
        [string] $Paging,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'All')]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'All')]
        [switch] $AllRecords = $false
    )

    if ($AlarmId) {
        $URISuffix = $URISuffix -f $AlarmId
    } else {

        if ($AllRecords) {
            $URISuffix = $URISuffix -f "true"
        } else {
            $URISuffix = $URISuffix -f "false"
        }
    }

    [hashtable]$Params = @{
        VSAConnection = $VSAConnection
        URISuffix     = $URISuffix
        Filter        = $Filter
        Paging        = $Paging
        Sort          = $Sort
    }

    foreach ( $key in $Params.Keys.Clone()  ) {
        if ( -not $Params[$key]) { $Params.Remove($key) }
    }

    return Invoke-VSARestMethod @Params
}

New-Alias -Name Get-VSAAlarms -Value Get-VSAAlarm
Export-ModuleMember -Function Get-VSAAlarm -Alias Get-VSAAlarms