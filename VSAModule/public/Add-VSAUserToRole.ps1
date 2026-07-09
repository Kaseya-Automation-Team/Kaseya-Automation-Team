function Add-VSAUserToRole
{
    <#
    .Synopsis
       Adds a new role to user
    .DESCRIPTION
       Adds a new role to the specified VSA user.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER RoleId
        Specifies id of the role
    .PARAMETER UserId
        Specifies id of the user
    .EXAMPLE
       Add-VSAUserToRole -RoleId 10001 -UserId 20002
    .EXAMPLE
       Add-VSAUserToRole -VSAConnection $connection -RoleId 10001 -UserId 20002
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       No output
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/system/roles/{0}/users/{1}",

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $RoleId,

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
	
	return Invoke-VSAWriteRequest -Method 'PUT' -URISuffix ($($URISuffix -f $RoleId, $UserId)) -VSAConnection $VSAConnection
}

Export-ModuleMember -Function Add-VSAUserToRole