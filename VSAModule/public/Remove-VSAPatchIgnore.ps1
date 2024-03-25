function Remove-VSAPatchIgnore
{
    <#
    .Synopsis
       Removes the Ignore setting for a missing patch for an agent machine.
    .DESCRIPTION
       Deletes a patch.
       Removes the Ignore setting for a missing patch for an agent machine.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AgentId
        Specifies id of agent machine
    .PARAMETER PatchDataId
        Specifies id of patch
    .EXAMPLE
       Remove-VSAPatchIgnore -AgentId 979868787875855 -PatchDataId 190
    .EXAMPLE
       Remove-VSAPatchIgnore -VSAConnection $connection -AgentId 979868787875855 -PatchDataId 190
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
        [string] $URISuffix = "api/v1.0/assetmgmt/patch/{0}/{1}/setignore",
        [parameter(Mandatory = $true,  
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentID,
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $true)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $true)]
        [ValidateNotNullOrEmpty()] 
        [string] $PatchDataId
)
	
    $URISuffix = $URISuffix -f $AgentId, $PatchDataId

    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'DELETE'
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Remove-VSAPatchIgnore