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

    [CmdletBinding(SupportsShouldProcess)]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
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

        [parameter(Mandatory = $true,  
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $PatchDataId
)
    process {

    return Invoke-VSAWriteRequest -Method 'DELETE' -URISuffix ($($URISuffix -f $AgentId, $PatchDataId)) -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}

Export-ModuleMember -Function Remove-VSAPatchIgnore