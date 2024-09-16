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
        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
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
	
	[hashtable]$Params =@{
        URISuffix = $($URISuffix -f $RoleId, $UserId)
        Method = 'PUT'
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}

Export-ModuleMember -Function Add-VSAUserToRole