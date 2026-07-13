function Close-VSAUserSession
{
    <#
    .Synopsis
       Closes the current VSA user session.
    .DESCRIPTION
       Ends the current VSA REST API session (logout). After this call the session token is no
       longer valid and a new connection must be established.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .EXAMPLE
       Close-VSAUserSession -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if the session was closed successfully.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/system/users/session'
    )
    process {
        return Invoke-VSAWriteRequest -Method DELETE -URISuffix $URISuffix `
            -VSAConnection $VSAConnection -Caller $PSCmdlet -Operation 'DELETE (close user session)'
    }
}
Export-ModuleMember -Function Close-VSAUserSession
