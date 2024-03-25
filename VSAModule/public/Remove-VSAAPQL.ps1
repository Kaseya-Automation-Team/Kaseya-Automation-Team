function Remove-VSAAPQL
{
    <#
    .Synopsis
       Removes agent procedure from quick launch
    .DESCRIPTION
       Removes specified agent procedure from quick launch in "Quick View" window.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies id of the agent machine
    .PARAMETER AgentProcedureId
        Specifies id of agent procedire
    .EXAMPLE
       Remove-VSAAPQL -AgentProcedureId 2312
    .EXAMPLE
       Remove-VSAAPQL -VSAConnection $connection -AgentProcedureId 2312
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
        [string] $URISuffix = "api/v1.0/automation/agentProcs/quicklaunch/{0}",
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $AgentProcedureId
)
    
    $URISuffix = $URISuffix -f $AgentProcedureId
    
    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'DELETE'
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Remove-VSAAPQL