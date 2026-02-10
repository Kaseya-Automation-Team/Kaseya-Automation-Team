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
       True if successful
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/assetmgmt/agents/{0}/settings/tempdir",

        [Parameter(Mandatory = $true)]
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
        [string] $TempDir
)
    $TempDir = [Regex]::Escape($TempDir)
	
    [hashtable]$Params =@{
        URISuffix = $($URISuffix -f $AgentId)
        Method = 'PUT'
        Body = $("[{""key"":""$TempDir"",""value"":""$TempDir""}]")
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}

Export-ModuleMember -Function Update-VSAAgentTempDir