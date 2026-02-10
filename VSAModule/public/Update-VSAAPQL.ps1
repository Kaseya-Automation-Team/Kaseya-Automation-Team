function Update-VSAAPQL
{
    <#
    .Synopsis
       Add agent procedure to quick launch
    .DESCRIPTION
       Adds specified agent procedure to quick launch in "Quick View" window.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies id of the agent machine
    .PARAMETER AgentProcedureId
        Specifies id of agent procedire
    .EXAMPLE
       Update-VSAAPQL -AgentProcedureId 2312
    .EXAMPLE
       Update-VSAAPQL -VSAConnection $connection -AgentProcedureId 2312
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if successful
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/automation/agentProcs/quicklaunch/{0}",

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentProcedureId
)
    
    [hashtable]$Params =@{
        URISuffix = $($URISuffix -f $AgentProcedureId)
        Method = 'PUT'
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}

Export-ModuleMember -Function Update-VSAAPQL