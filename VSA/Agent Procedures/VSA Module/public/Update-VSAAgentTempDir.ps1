function Update-VSAAgentTempDir
{
    <#
    .Synopsis
       Updates the temp directory for an agent.
    .DESCRIPTION
       Updates the temp directory for an agentt.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AgentId
        Specifies numeric id of agent machine
    .PARAMETER TempDir
        Specifies temp directory path
    .EXAMPLE
       Update-VSAAgentTempDir -AgentId 342343222 -TempDir "c:\temp"
    .EXAMPLE
       Update-VSAAgentTempDir -VSAConnection $VSAConnection -AgentId 342343222 -TempDir "c:\temp"
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
        [string] $URISuffix = "api/v1.0/assetmgmt/agents/{0}/settings/tempdir",
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $AgentId,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $TempDir
)
    $URISuffix = $URISuffix -f $AgentId
	
    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'PUT'
    }

    $Body = ConvertTo-Json @(@{"key"="$TempDir"; "value"="$TempDir";})
	
    $Params.Add('Body', $Body)

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    Write-Host $Body

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Update-VSAAgentTempDir