function Reset-VSAUserPassword
{
    <#
    .Synopsis
       Triggers a password reset for a VSA user.
    .DESCRIPTION
       Initiates the password-reset workflow for the specified VSA user (by user name).
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER UserName
        Specifies the user name (logon name) whose password is reset.
    .EXAMPLE
       Reset-VSAUserPassword -UserName 'jdoe'
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if the reset was initiated successfully.
    .NOTES
        On hardened (post-2021) VSA builds this user-mutation endpoint may be blocked at the network
        layer. The call then fails with a VSAApiException whose ConnectionReset property is $true and
        whose StatusCode is 0 (the connection is reset before any HTTP status is returned) -- it is
        not a 403/404. Read-only user cmdlets (Get-VSAUser) are unaffected.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is invoked centrally by Invoke-VSAWriteRequest, which receives this cmdlet''s $PSCmdlet via -Caller (module-wide pattern).')]
    param (
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/system/users/{0}/passwordreset',

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $UserName
    )
    process {
        $URISuffix = $URISuffix -f [uri]::EscapeDataString($UserName)
        return Invoke-VSAWriteRequest -Method POST -URISuffix $URISuffix `
            -VSAConnection $VSAConnection -Caller $PSCmdlet -Operation 'POST (reset user password)'
    }
}
Export-ModuleMember -Function Reset-VSAUserPassword
