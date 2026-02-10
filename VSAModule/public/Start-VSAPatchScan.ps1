function Start-VSAPatchScan
{
    <#
    .Synopsis
       Scans an agent machine immediately for missing patches.
    .DESCRIPTION
       Scans an agent machine immediately for missing patches.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AgentId
        Specifies id of agent machine
    .EXAMPLE
       Start-VSAPatchScan -AgentId 979868787875855
    .EXAMPLE
       Start-VSAPatchScan -VSAConnection $connection -AgentId 979868787875855
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Success or failure
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/assetmgmt/patch/{0}/scannow",

        [parameter(Mandatory = $true,  
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentID
)
	
    $URISuffix = $URISuffix -f $AgentId

    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'PUT'
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}

Export-ModuleMember -Function Start-VSAPatchScan