function Set-VSAUserPassword
{
    <#
    .Synopsis
       Sets a VSA user's password.
    .DESCRIPTION
       Updates the password of an existing VSA user account.
       Takes either persistent or non-persistent connection information.

       SECURITY: this VSA endpoint carries the new password in the request URL path, so it is sent
       in clear text within the URI (over HTTPS). Prefer running this only over trusted networks.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER UserId
        Specifies the user account id.
    .PARAMETER NewPassword
        Specifies the new password.
    .EXAMPLE
       Set-VSAUserPassword -UserId 10001 -NewPassword 'N3w-P@ssw0rd!'
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if the update was successful.
    .NOTES
        On hardened (post-2021) VSA builds this user-mutation endpoint may be blocked at the network
        layer. The call then fails with a VSAApiException whose ConnectionReset property is $true and
        whose StatusCode is 0 (the connection is reset before any HTTP status is returned) -- it is
        not a 403/404. Read-only user cmdlets (Get-VSAUser) are unaffected.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/system/users/{0}/password/{1}/update',

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({ if ($_ -notmatch "^\d+$") { throw "Non-numeric Id" } return $true })]
        [string] $UserId,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $NewPassword
    )
    process {
        $URISuffix = $URISuffix -f $UserId, [uri]::EscapeDataString($NewPassword)
        return Invoke-VSAWriteRequest -Method PUT -URISuffix $URISuffix `
            -VSAConnection $VSAConnection -Caller $PSCmdlet -Operation 'PUT (update user password)'
    }
}
Export-ModuleMember -Function Set-VSAUserPassword
