function Get-VSACustomFields
{
<#
.Synopsis
   Returns VSA custom fields.
.DESCRIPTION
   Returns existing VSA custom fields.
   Takes either persistent or non-persistent connection information.
.PARAMETER VSAConnection
    Specifies existing non-persistent VSAConnection.
.PARAMETER URISuffix
    Specifies URI suffix if it differs from the default.
.PARAMETER AgentId
    Specifies AgentId to get custom fields.
.PARAMETER Filter
    Specifies REST API Filter.
.PARAMETER Paging
    Specifies REST API Paging.
.PARAMETER Sort
    Specifies REST API Sorting.
.EXAMPLE
   Get-VSACustomFields
.EXAMPLE
   Get-VSACustomFields -VSAConnection $connection
.INPUTS
   Accepts piped non-persistent VSAConnection 
.OUTPUTS
   Array of objects that represent existing VSA Custom Fields
#>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/assetmgmt/assets/{0}/customfields',

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentId,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Paging,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort
    )

    $URISuffix = $($URISuffix -f $AgentId) -replace '//', '/' # URI suffix actualization

    [hashtable]$Params =@{
        URISuffix = $URISuffix
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}
    if($Filter)        {$Params.Add('Filter', $Filter)}
    if($Paging)        {$Params.Add('Paging', $Paging)}
    if($Sort)          {$Params.Add('Sort', $Sort)}

    return Get-VSAItems @Params
}
Export-ModuleMember -Function Get-VSACustomFields