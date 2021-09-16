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
       Update-VSAAgentNote -NoteId '1' -Note 'Changed note'
    .EXAMPLE
       Update-VSAAgentNote -NoteId '1' -Note 'Changed note' -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if update was successful
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/assetmgmt/agent/notes',

        [Parameter(Mandatory = $true)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $NoteId,

        [Parameter(Mandatory = $true)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $Note

        )

    [bool]$result = $false
    [hashtable]$BodyHT=@{}
    $BodyHT.Add($NoteId, $Note)

    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'PUT'
        Body = $(ConvertTo-Json $BodyHT)
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    If ( $NoteId -in $(Get-VSAAgentNote | Select-Object -ExpandProperty ID) ) {
        $result = Update-VSAItems @Params
    } else {
        $Message = "The agent note with ID `'$NoteId`' does not exist"
        Log-Event -Msg $Message -Id 4000 -Type "Error"
        throw $Message
    }

    return $result
}
Export-ModuleMember -Function Update-VSAAgentNote