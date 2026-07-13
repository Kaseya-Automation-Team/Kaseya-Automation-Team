function Set-VSATemporaryAgentName
{
    <#
    .Synopsis
       Sets the name of a temporary agent.
    .DESCRIPTION
       Updates the display name of an existing temporary (Live Connect) agent.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AgentGuid
        Specifies the temporary agent guid.
    .PARAMETER Name
        Specifies the new name for the temporary agent.
    .PARAMETER PartitionId
        Specifies the tenant partition id.
    .EXAMPLE
       Set-VSATemporaryAgentName -AgentGuid 123456789 -Name 'Bench-01'
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if the update was successful.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/temporaryagent/{0}/name',

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if ($_ -notmatch "^\d+$") { throw "Non-numeric Id" }
            return $true
        })]
        [string] $AgentGuid,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if ((-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$")) { throw "Non-numeric Id" }
            return $true
        })]
        [string] $PartitionId
    )
    process {
        $URISuffix = $URISuffix -f $AgentGuid
        [hashtable] $BodyHT = ConvertTo-VSARequestBody -BoundParameters $PSBoundParameters -Include @('Name', 'PartitionId')
        return Invoke-VSAWriteRequest -Body $BodyHT -Method PUT -URISuffix $URISuffix `
            -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function Set-VSATemporaryAgentName
