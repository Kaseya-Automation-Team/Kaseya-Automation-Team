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
    [CmdletBinding()]
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
    [hashtable]$Params = @{}
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    If ( $NoteId -in $(Get-VSAAgentNote @Params | Select-Object -ExpandProperty ID) ) {

        $Params.URISuffix = $URISuffix
        $Params.Method    = 'PUT'
        $Params.Body      = $("{{""{0}"":""{1}""}}"-f $NoteId, $Note)

        return Invoke-VSARestMethod @Params
    } else {
        throw "The agent note with ID `'$NoteId`' does not exist"
    }
}
Export-ModuleMember -Function Update-VSAAgentNote