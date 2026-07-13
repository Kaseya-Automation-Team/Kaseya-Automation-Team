function Send-VSATemporaryAgentEmail
{
    <#
    .Synopsis
       Emails a temporary agent install link.
    .DESCRIPTION
       Sends an email containing the temporary (Live Connect) agent install link to a recipient.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AgentGuid
        Specifies the temporary agent guid.
    .PARAMETER EmailAddress
        Specifies the recipient email address.
    .PARAMETER PartitionId
        Specifies the tenant partition id.
    .EXAMPLE
       Send-VSATemporaryAgentEmail -AgentGuid 123456789 -EmailAddress 'tech@example.com'
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if the email was sent successfully.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/temporaryagent/email',

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
        [string] $EmailAddress,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if ((-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$")) { throw "Non-numeric Id" }
            return $true
        })]
        [string] $PartitionId
    )
    process {
        [hashtable] $BodyHT = ConvertTo-VSARequestBody -BoundParameters $PSBoundParameters -Include @('AgentGuid', 'EmailAddress', 'PartitionId')
        return Invoke-VSAWriteRequest -Body $BodyHT -Method POST -URISuffix $URISuffix `
            -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function Send-VSATemporaryAgentEmail
