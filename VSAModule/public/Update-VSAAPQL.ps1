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

        [parameter(DontShow, Mandatory=$false)]
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
    process {
    
    return Invoke-VSAWriteRequest -Method 'PUT' -URISuffix ($($URISuffix -f $AgentProcedureId)) -VSAConnection $VSAConnection
    }
}

Export-ModuleMember -Function Update-VSAAPQL