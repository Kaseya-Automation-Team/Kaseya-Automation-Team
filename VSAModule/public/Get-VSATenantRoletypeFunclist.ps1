function Get-VSATenantRoletypeFunclist {
    <#
    .Synopsis
       Returns an array of funclist entries.
    .DESCRIPTION
       Returns an array of funclist entries for a specified roletype id OR for each roletype.
       Takes either Tenant or non-Tenant connection information.
    .PARAMETER VSAConnection
        Specifies existing non-Tenant VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER RoleTypeId
        Specifies roletype id to return an array of funclist entries.
    .PARAMETER Filter
        Specifies REST API Filter.
    .PARAMETER Paging
        Specifies REST API Paging.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .PARAMETER ResolveIDs
        Return asset types as well as their respective IDs.
    .EXAMPLE
       Get-VSATenantRoletypeFunclist -RoleTypeId 4
    .INPUTS
       Accepts piped non-Tenant VSAConnection 
    .OUTPUTS
       Array of funclist entries.
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/tenantmanagement/roletypes',

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $RoleTypeId,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Paging,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort
    )
    
    if( -not [string]::IsNullOrEmpty($RoleTypeId) ) {
        $URISuffix += "/$RoleTypeId"
    }
    [hashtable]$Params =@{
        URISuffix = $URISuffix
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}
New-Alias -Name Get-VSATenantRoletypesFunclists -Value Get-VSATenantRoletypeFunclist
Export-ModuleMember -Function Get-VSATenantRoletypeFunclist -Alias Get-VSATenantRoletypesFunclists