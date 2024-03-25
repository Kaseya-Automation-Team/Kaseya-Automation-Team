function Remove-VSAPatch
{
    <#
    .Synopsis
       Deletes a patch.
    .DESCRIPTION
       Deletes a patch.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AgentIds
        Specifies ids of agent machines
    .EXAMPLE
       Remove-VSAPatch -AgentIds "979868787875855, 239868787875855"
    .EXAMPLE
       Remove-VSAPatch -VSAConnection $connection -AgentIds "979868787875855, 239868787875855"
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
        [string] $URISuffix = "api/v1.0/assetmgmt/patch?agentGuids={0}",
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $true)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $true)]
        [ValidateNotNullOrEmpty()] 
        [string] $AgentIds
)
	
    $URISuffix = $URISuffix -f $AgentIds

    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'DELETE'
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Remove-VSAPatch