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

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
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
	
    $URISuffix = 

    [hashtable]$Params =@{
        URISuffix = $($URISuffix -f $AgentIds)
        Method = 'DELETE'
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}

Export-ModuleMember -Function Remove-VSAPatch