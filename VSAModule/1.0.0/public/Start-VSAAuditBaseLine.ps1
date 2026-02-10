function Start-VSAAuditBaseLine
{
    <#
    .Synopsis
       Runs a baseline audit.
    .DESCRIPTION
       Runs a baseline audit immediately for a single agent. A baseline audit shows the configuration of the system in its original state. Typically a baseline audit is performed when a system is first set up.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .EXAMPLE
       Start-VSAAuditBaseLine -AgentID 10001
    .EXAMPLE
       Start-VSAAuditBaseLine -AgentID 10001 -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if start of baseline audit was successful.
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/assetmgmt/audit/baseline/{0}/runnow', 
 
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
    
    $URISuffix = $URISuffix -f $AgentID

    [hashtable]$Params = @{
        URISuffix = $($URISuffix -f $AgentID)
        Method = 'PUT'
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}
Export-ModuleMember -Function Start-VSAAuditBaseLine