function Get-VSARoles
{
    <#
    .Synopsis
       Returns info about all VSA roles or single role.
    .DESCRIPTION
       Returns info about all VSA roles or single role.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER RoleId
        If specified, returns details about single role.
    .PARAMETER ResolveIDs
        Return Role Types as well as their IDs.
    .PARAMETER Filter
        Specifies REST API Filter.
    .PARAMETER Paging
        Specifies REST API Paging.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .EXAMPLE
       Get-VSARoles
	.EXAMPLE
	   Get-VSARoles -ResolveIDs
    .EXAMPLE
       Get-VSARoles -RoleId 2
    .EXAMPLE
       Get-VSARoles -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Array of objects that represent existing VSA user roles or single role
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/system/roles',

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $RoleId,

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
        [string] $Sort,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [switch] $ResolveIDs

    )

    if ($RoleId) {
        $URISuffix = "api/v1.0/system/roles/$RoleId"
    }

    [hashtable]$Params =@{
        URISuffix = $URISuffix
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}
    if($Filter)        {$Params.Add('Filter', $Filter)}
    if($Paging)        {$Params.Add('Paging', $Paging)}
    if($Sort)          {$Params.Add('Sort', $Sort)}

    $result = Get-VSAItems @Params

    if ($ResolveIDs)
    {
        [hashtable]$ResolveParams =@{}
        if($VSAConnection) {$ResolveParams.Add('VSAConnection', $VSAConnection)}

        [hashtable]$RoleTypesDictionary = @{}

        Foreach( $RoleType in $(Get-VSARoleTypes @ResolveParams) )
        {
            if ( -Not $RoleTypesDictionary[$RoleType.RoleTypeId]) {
                $RoleTypesDictionary.Add($RoleType.RoleTypeId, $($RoleType | Select-Object * -ExcludeProperty RoleTypeId))
            }
        }

        $result = $result | Select-Object -Property *, `
            @{Name = 'RoleTypes'; Expression = { $RoleTypesDictionary[$_.RoleTypeIds] }}
    }
    return $result
}
Export-ModuleMember -Function Get-VSARoles