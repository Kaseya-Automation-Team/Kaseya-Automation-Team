function Get-VSAAgentUptime {
    <#
    .Synopsis
       Returns an array of agent uptime records
    .DESCRIPTION
       Returns an array of agent uptime records.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER Since
        Specifies start date.
    .PARAMETER Filter
        Specifies REST API Filter.
    .PARAMETER Paging
        Specifies REST API Paging.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .EXAMPLE
       Get-VSAAgentUptime -Since "2021-03-04"
    .EXAMPLE
       Get-VSAAgentUptime -VSAConnection $connection -Since "2021-03-04"
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Array of items that represent system agent views
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/assetmgmt/agents/uptime/{0}',

        [Parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Date in yyy-mm-dd format')]
        [ValidateScript({
            if( $_ -notmatch "\d{4}\-(0?[1-9]|1[012])\-(0?[1-9]|[12][0-9]|3[01])*" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $Since,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Paging,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort
    )

    [hashtable]$Params = @{
        URISuffix     = $($URISuffix -f $Since)
        VSAConnection = $VSAConnection
        Filter        = $Filter
        Paging        = $Paging
        Sort          = $Sort
    }

    foreach ( $key in $Params.Keys.Clone()  ) {
        if ( -not $Params[$key]) { $Params.Remove($key) }
    }

    return Invoke-VSARestMethod @Params
}

New-Alias -Name Get-VSAAgentsUptime -Value Get-VSAAgentUptime
Export-ModuleMember -Function Get-VSAAgentUptime -Alias Get-VSAAgentsUptime