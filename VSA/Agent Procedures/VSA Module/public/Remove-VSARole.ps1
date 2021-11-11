function Remove-VSARole
{
    <#
    .Synopsis
       Removes user role
    .DESCRIPTION
       Removes user role with specified role id
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER RoleId
        Specifies numeric id of machine group
    .EXAMPLE
       Remove-VSARole -RoleId 581411914
    .EXAMPLE
       Remove-VSARole -VSAConnection $connection -RoleId 581411914
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

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/system/roles/{0}",

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $RoleId
)
    $URISuffix = $URISuffix -f $RoleId
	
    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'DELETE'
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Remove-VSARole