function Add-VSARole
{
    <#
    .Synopsis
       Adds new user role
    .DESCRIPTION
       Adds new user role in VSA with specified role type ids
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER RoleName
        Specifies name of the role
    .PARAMETER RoleTypeIds
        Specifies array of role type ids
    .EXAMPLE
       Add-VSARole -RoleName "Remote desktop" -RoleTypeIds 4, 6, 100, 101
    .EXAMPLE
       Add-VSARole -VSAConnection $connection -RoleName "Remote desktop" -RoleTypeIds 4, 6, 100, 101
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       No output
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NonPersistent')]
        [VSAConnection] $VSAConnection,
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'NonPersistent')]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'Persistent')]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/system/roles",
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $RoleName,
		[parameter(ParameterSetName = 'Persistent', Mandatory=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true)]
        [ValidateNotNullOrEmpty()] 
        [string[]] $RoleTypeIds=@()
)
    
    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'POST'
    }

	$Body = ConvertTo-Json @{"RoleName"=$RoleName; "RoleTypeIds"=$RoleTypeIds}
	
    $Params.Add('Body', $Body)

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Add-VSARole