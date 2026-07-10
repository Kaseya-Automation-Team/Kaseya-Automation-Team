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
    [CmdletBinding(SupportsShouldProcess)]
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
        [ValidateNotNullOrEmpty()]
        [string] $Note

        )
    process {

    return Invoke-VSAWriteRequest -Body (ConvertTo-Json $Note -Compress) -Method 'POST' -URISuffix ($($URISuffix -f $AgentId)) -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
New-Alias -Name Add-VSAAgentNote -Value New-VSAAgentNote
Export-ModuleMember -Function New-VSAAgentNote -Alias Add-VSAAgentNote