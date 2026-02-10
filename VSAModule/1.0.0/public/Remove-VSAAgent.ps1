function Remove-VSAAgent
{
    <#
    .Synopsis
       Deletes an agent
    .DESCRIPTION
       Deletes an agent. Provides an option to wait for the agent to uninstall on the managed machine first.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AgentId
        Specifies numeric id of machine group
    .PARAMETER UninstallFirst
        Specifies if agent software should be uninstalled first
    .EXAMPLE
       Remove-VSAAgent -AgentId 581411914
    .EXAMPLE
       Remove-VSAAgent -AgentId 581411914 -UninstallFirst
    .EXAMPLE
       Remove-VSAAgent -VSAConnection $connection -AgentId 581411914
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       No output
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/assetmgmt/agents/{0}/{1}",

        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentId,

        [switch] $UninstallFirst = $false
)
    [hashtable]$Params =@{
        URISuffix = $( $URISuffix -f $AgentId, $UninstallFirst.ToString() )
        Method    = 'DELETE'
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}
Export-ModuleMember -Function Remove-VSAAgent