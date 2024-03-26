function Get-VSARoleTypes
{
    <#
    .Synopsis
       Returns VSA user role types.
    .DESCRIPTION
       Returns existing VSA user role types.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER RoleTypeId
        Specifies RoleTypeId to return.
    .PARAMETER Filter
        Specifies REST API Filter.
    .PARAMETER Paging
        Specifies REST API Paging.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .EXAMPLE
       Get-VSARoleTypes
    .EXAMPLE
       Get-VSARoleTypes -VSAConnection $connection
    .EXAMPLE
       Get-VSARoleTypes -RoleTypeId 100
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Array of objects that represent existing VSA user role types.
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/system/roletypes',

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $RoleTypeId,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Paging,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort
    )



    if ($RoleTypeId) {
        $URISuffix = "api/v1.0/system/roletypes/$RoleTypeId"
    }

    [hashtable]$Params =@{
        URISuffix = $URISuffix
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}
    if($Filter)        {$Params.Add('Filter', $Filter)}
    if($Paging)        {$Params.Add('Paging', $Paging)}
    if($Sort)          {$Params.Add('Sort', $Sort)}

    return Get-VSAItems @Params
}
Export-ModuleMember -Function Get-VSARoleTypes