function Add-VSAAgentNote {
    <#
    .Synopsis
       Adds a note to the specified agent associated with the current user.
    .DESCRIPTION
       Adds a note to the specified agent associated with the current user.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AgentId
        Agent Id to add the note.
    .PARAMETER Note
        Note text.
    .EXAMPLE
       Add-VSAAgentNote -AgentId '10001' -Note 'A note to add'
    .EXAMPLE
       Add-VSAAgentNote -AgentId '10001' -Note 'A note to add' -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if creation was successful
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/assetmgmt/agent/{0}/note',

        [Parameter(Mandatory = $true)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $AgentId,

        [Parameter(Mandatory = $true)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $Note

        )

    [bool]$result = $false

    $URISuffix = $URISuffix -f $AgentId

    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'POST'
        Body = "`"$Note`""
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    If ( $AgentId -in $(Get-VSAAgents | Select-Object -ExpandProperty AgentID) ) {
        $result = Update-VSAItems @Params
    } else {
        $Message = "The asset with Agent ID `'$AgentId`' does not exist"
        Log-Event -Msg $Message -Id 4000 -Type "Error"
        throw $Message
    }

    return $result
}
Export-ModuleMember -Function Add-VSAAgentNote