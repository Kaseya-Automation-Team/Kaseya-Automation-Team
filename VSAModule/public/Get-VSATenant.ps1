function Get-VSATenant {
    <#
    .Synopsis
       Returns tenant's properties
    .DESCRIPTION
       Returns properties for the tenant partition your API authentication provides access to in the VSA.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .EXAMPLE
       Get-VSATenant
    .EXAMPLE
       Get-VSATenant -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Array of tenant's properties
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
        [string] $URISuffix = 'api/v1.0/tenant'
    )

    [hashtable]$Params =@{
        URISuffix = $URISuffix
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Get-VSAItems @Params
}

Export-ModuleMember -Function Get-VSATenant