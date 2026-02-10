function Get-VSAAgent
{
    <#
    .SYNOPSIS
        Retrieves all VSA agents or a specified one.
    .DESCRIPTION
        This script returns all VSA agents or a specific agent if an agent ID is supplied. 
        It supports both persistent and non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies an existing non-persistent VSA connection.
    .PARAMETER URISuffix
        Specifies the URI suffix if it differs from the default.
    .PARAMETER AgentId
        Specifies the ID of the agent machine.
    .PARAMETER Filter
        Specifies the REST API filter.
    .PARAMETER Paging
        Specifies the REST API paging.
    .PARAMETER Sort
        Specifies the REST API sorting.
    .EXAMPLE
        Get-VSAAgent
        Retrieves all VSA agents.
    .EXAMPLE
        Get-VSAAgent -AgentId 3423232424
        Retrieves the VSA agent with the specified ID.
    .EXAMPLE
        Get-VSAAgent -VSAConnection $connection
        Retrieves VSA agents using the specified non-persistent VSA connection.
    .INPUTS
        Accepts a piped non-persistent VSAConnection.
    .OUTPUTS
        Returns an array of custom objects representing the existing VSA agents or a specific agent.
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
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'All')]
        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/assetmgmt/agents',

        [Alias('ID')]
        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentId,

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
        [string] $Sort
    )


    if( -not [string]::IsNullOrWhiteSpace( $AgentId) ) {
        $URISuffix = "$URISuffix/$AgentId"
    }

    [hashtable]$Params =@{
        URISuffix = $URISuffix
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

Export-ModuleMember -Function Get-VSAAgent