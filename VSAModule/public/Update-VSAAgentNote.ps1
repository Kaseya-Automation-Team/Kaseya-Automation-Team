function Update-VSAAgentNote {
    <#
    .Synopsis
       Changes an agent note.
    .DESCRIPTION
       Changes an agent note.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER NoteId
        Id of note that is changed.
    .PARAMETER Note
        Note text.
    .EXAMPLE
       Update-VSAAgentNote -NoteId 1 -Note 'Changed note'
    .EXAMPLE
       Update-VSAAgentNote -NoteId 1 -Note 'Changed note' -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if successful
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is invoked centrally by Invoke-VSAWriteRequest, which receives this cmdlet''s $PSCmdlet via -Caller (module-wide pattern).')]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/assetmgmt/agent/notes',

        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $NoteId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Note

    )
    process {
    return Invoke-VSAWriteRequest -Body (ConvertTo-Json @{ $NoteId = $Note } -Compress) -Method 'PUT' -URISuffix ($URISuffix) -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function Update-VSAAgentNote