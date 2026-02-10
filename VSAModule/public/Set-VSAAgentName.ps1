function Set-VSAAgentName
{
    <#
    .Synopsis
       Renames the agent
    .DESCRIPTION
       Renames the agent
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AgentId
        Specifies numeric id of machine group
    .PARAMETER Name
        Specifies new name of agent
    .EXAMPLE
       Set-VSAAgentName -AgentId 581411914 -Name "newname"
    .EXAMPLE
       Set-VSAAgentName -VSAConnection $connection -AgentId 581411914 -Name "newname"
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       No output
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/assetmgmt/agents/{0}/rename/{1}",

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentId,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Name
)
	
    [hashtable]$Params =@{
        URISuffix = $($URISuffix -f $AgentId, $Name)
        Method = 'PUT'
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}

New-Alias -Name Update-VSAAgentName -Value Set-VSAAgentName
Export-ModuleMember -Function Set-VSAAgentName -Alias Update-VSAAgentName