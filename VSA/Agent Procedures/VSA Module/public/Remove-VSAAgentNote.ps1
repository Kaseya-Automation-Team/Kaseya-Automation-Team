function Remove-VSAAgentNote {
    <#
    .Synopsis
       Removes an agent note.
    .DESCRIPTION
       Removes an agent note.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER NoteId
        Id of note that is changed.
    .EXAMPLE
       Remove-VSAAgentNote -NoteId '1'
    .EXAMPLE
       Remove-VSAAgentNote -NoteId '1' -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if removing was successful.
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/assetmgmt/agent/note/{0}',

        [Parameter(Mandatory = $true)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $NoteId
        )

    $URISuffix = $URISuffix -f $NoteId

    [bool]$result = $false

    [hashtable]$Params = @{}
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    If ( $NoteId -in $(Get-VSAAgentNote @Params | Select-Object -ExpandProperty ID) ) {

        $Params.Add('URISuffix', $URISuffix)
        $Params.Add('Method', 'DELETE')

        $result = Update-VSAItems @Params
    } else {
        $Message = "The agent note with ID `'$NoteId`' does not exist"
        Log-Event -Msg $Message -Id 4000 -Type "Error"
        throw $Message
    }
    return $result
}
Export-ModuleMember -Function Remove-VSAAgentNote