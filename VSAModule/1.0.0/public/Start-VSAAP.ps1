function Start-VSAAP
{
    <#
    .Synopsis
       Runs agent procedure
    .DESCRIPTION
       Runs an agent procedure immediately for a single agent.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AgentId
        Specifies id of the agent machine
    .PARAMETER AgentProcedureId
        Specifies id of agent procedire
    .EXAMPLE
       Start-VSAAP -AgentId 34223222 -AgentProcedureId 2312
    .EXAMPLE
       Start-VSAAP -VSAConnection $connection -AgentId 34223222 -AgentProcedureId 2312
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
        [string] $URISuffix = "api/v1.0/automation/agentprocs/{0}/{1}/runnow",

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
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentProcedureId
)
    
    $URISuffix = $URISuffix -f $AgentId, $AgentProcedureId
    
    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'PUT'
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}

Export-ModuleMember -Function Start-VSAAP