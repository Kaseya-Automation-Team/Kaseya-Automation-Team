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
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/assetmgmt/patch?agentGuids={0}",

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            foreach ($item in $_) {
                if ( -not [decimal]::TryParse($item, [ref]$null) ) {
                    throw "All elements must be numeric. '$item' is not a valid number."
                }
            }
            return $true
        })]
        [string[]] $AgentIds
)
    process {
    # F-41: the dangling '$URISuffix = ' (no right-hand side) here previously nulled out the
    # parameter's default URISuffix before every use. Removed.
    #
    # F-13 (resolved via live Swagger docs/v1.0): DELETE /assetmgmt/patch takes a single required
    # 'agentGuids' query STRING (Swagger type=string, not an array), so multiple agent IDs are
    # comma-joined into one value. The prior '-f' with a [string[]] substituted only the first ID
    # into {0} and silently dropped the rest. NOTE: the comma separator has NOT been confirmed by a
    # live mutating call (validation was GET-only); if the server rejects raw commas, URL-encode.

    return Invoke-VSAWriteRequest -Method 'DELETE' -URISuffix ($($URISuffix -f ($AgentIds -join ','))) -VSAConnection $VSAConnection
    }
}

Export-ModuleMember -Function Remove-VSAPatch