function Disable-VSAUser
{
    <#
    .Synopsis
       Disables a single user account record.
    .DESCRIPTION
       Disables a single user account record.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER UserId
        Specifies a user account Id.
    .PARAMETER AdminName
        Specifies a user account name.
    .EXAMPLE
       Disable-VSAUser -UserId 10001
    .EXAMPLE
       Disable-VSAUser -VSAConnect $connection -UserId 10001
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if addition was successful.
        .NOTES
        On hardened (post-2021) VSA builds this user-mutation endpoint may be blocked at the network
        layer. The call then fails with a VSAApiException whose .ConnectionReset is $true and
        .StatusCode is 0 (the connection is reset before any HTTP status is returned) -- it is not a
        403/404. Read-only user cmdlets (Get-VSAUser) are unaffected.
#>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'ById')]
    #[CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/system/users/{0}/disable',

        [Alias('ID')]
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $UserId
    )    

    return Invoke-VSAWriteRequest -Method 'PUT' -URISuffix ($($URISuffix -f $UserId)) -VSAConnection $VSAConnection -Caller $PSCmdlet
}
Export-ModuleMember -Function Disable-VSAUser