function Stop-VSAScheduledAP
{
    <#
    .Synopsis
       Cancels scheduled agent procedure
    .DESCRIPTION
       Cancels a scheduled agent procedure running on an agent machine.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AgentId
        Specifies id of the agent machine
    .PARAMETER AgentProcedureId
        Specifies id of the agent procedure
    .EXAMPLE
       Stop-VSAScheduledAP -AgentId 581411914 -AgentProcedureId 2312
    .EXAMPLE
       Stop-VSAScheduledAP -VSAConnection $connection -AgentId 581411914 -AgentProcedureId 2312
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
        [string] $URISuffix = "api/v1.0/automation/agentprocs/{0}/{1}",

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
	
    [hashtable]$Params =@{
        URISuffix = $($URISuffix -f $AgentId, $AgentProcedureId)
        Method = 'DELETE'
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}

Export-ModuleMember -Function Stop-VSAScheduledAP