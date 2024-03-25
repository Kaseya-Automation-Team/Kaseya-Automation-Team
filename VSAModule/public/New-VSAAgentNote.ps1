function New-VSAAgentNote {
    <#
    .Synopsis
        Adds a note to the specified agent associated with the current user.
    .DESCRIPTION
        Adds a note to the specified agent associated with the current user.
    .PARAMETER VSAConnection
        Specifies a non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AgentId
        Agent Id to add the note.
    .PARAMETER Note
        Note text.
    .EXAMPLE
       New-VSAAgentNote -AgentId '10001' -Note 'A note to add' -VSAConnection $connection
    .INPUTS
       Accepts piped VSAConnection 
    .OUTPUTS
       True if creation was successful
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/assetmgmt/agent/{0}/note',

        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentId,

        [Parameter(Mandatory = $true)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $Note

        )

    [bool]$result = $false

    $URISuffix = $URISuffix -f $AgentId

    [hashtable]$Params = @{
        VSAConnection = $VSAConnection
        URISuffix     = $URISuffix
        Method        = 'POST'
        Body          = "`"$Note`""
    }
    #Remove empty keys
    foreach ( $key in $Params.Keys.Clone() ) {
        if ( -not $Params[$key] )  { $Params.Remove($key) }
    }

    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        "New-VSAAgentNote. $($Params | Out-String)" | Write-Debug
    }

    $GetAgentParams = @{ AgentId = $AgentId }
    if ($VSAConnection) {$GetAgentParams.Add('VSAConnection', $VSAConnection)}

    If ( $AgentId -in $(Get-VSAAgent @GetAgentParams | Select-Object -ExpandProperty AgentID) ) {
        $result = Invoke-VSARestMethod @Params
    } else {
        $Message = "Could not find an asset by the Agent ID `'$AgentId`'!"
        throw $Message
    }

    return $result
}
New-Alias -Name Add-VSAAgentNote -Value New-VSAAgentNote
Export-ModuleMember -Function New-VSAAgentNote -Alias Add-VSAAgentNote