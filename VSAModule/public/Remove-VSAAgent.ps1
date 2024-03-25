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
        [string] $URISuffix = "api/v1.0/assetmgmt/agents/{0}/{1}",
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentId,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$false)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [switch] $UninstallFirst = $false
)
    $URISuffix = $URISuffix -f $AgentId, $UninstallFirst
	
    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'DELETE'
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Remove-VSAAgent