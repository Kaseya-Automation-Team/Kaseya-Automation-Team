function Start-VSAAuditSysInfo
{
    <#
    .Synopsis
       Runs a sysinfo audit.
    .DESCRIPTION
       Runs a sysinfo audit immediately for a single agent. The sysinfo audit shows all DMI / SMBIOS data of the system as of the last system info audit. This data seldom changes and typically only needs to be run once.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .EXAMPLE
       Start-VSAAuditSysInfo -AgentID 10001
    .EXAMPLE
       Start-VSAAuditSysInfo -AgentID 10001 -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if start of baseline audit was successful.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param ( 
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/assetmgmt/audit/sysinfo/{0}/runnow', 
 
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
    

    return Invoke-VSAWriteRequest -Method 'PUT' -URISuffix ($($URISuffix -f $AgentID)) -VSAConnection $VSAConnection -Caller $PSCmdlet
}
Export-ModuleMember -Function Start-VSAAuditSysInfo