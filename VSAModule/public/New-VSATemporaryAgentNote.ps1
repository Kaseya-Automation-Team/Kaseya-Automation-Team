function New-VSATemporaryAgentNote
{
    <#
    .Synopsis
       Adds a note to a temporary agent.
    .DESCRIPTION
       Adds a note to an existing temporary (Live Connect) agent.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AgentGuid
        Specifies the temporary agent guid.
    .PARAMETER Notes
        Specifies the note text.
    .PARAMETER PartitionId
        Specifies the tenant partition id.
    .EXAMPLE
       New-VSATemporaryAgentNote -AgentGuid 123456789 -Notes 'Imaged and ready.'
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if the note was added successfully.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is invoked centrally by Invoke-VSAWriteRequest, which receives this cmdlet''s $PSCmdlet via -Caller (module-wide pattern).')]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/temporaryagent/{0}/notes',

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
        [string] $Notes,

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
        [hashtable] $BodyHT = ConvertTo-VSARequestBody -BoundParameters $PSBoundParameters -Include @('Notes', 'PartitionId')
        return Invoke-VSAWriteRequest -Body $BodyHT -Method POST -URISuffix $URISuffix `
            -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function New-VSATemporaryAgentNote
