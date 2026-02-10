function Get-VSACustomField
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
   Get-VSACustomField
.EXAMPLE
   Get-VSACustomField -VSAConnection $connection
.INPUTS
   Accepts piped non-persistent VSAConnection 
.OUTPUTS
   Array of objects that represent existing VSA Custom Fields
#>
    [CmdletBinding(DefaultParameterSetName='All')]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'All')]
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ById')]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'All')]
        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/assetmgmt/assets/{0}/customfields',

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'ById')]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentId,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'All')]
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'All')]
        [ValidateNotNullOrEmpty()] 
        [string] $Paging,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'All')]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort
    )

    $URISuffix = $($URISuffix -f $AgentId) -replace '//', '/' # URI suffix actualization

    [hashtable]$Params = @{
        VSAConnection = $VSAConnection
        URISuffix     = $URISuffix
        Filter        = $Filter
        Paging        = $Paging
        Sort          = $Sort
    }

    #Remove empty keys
    foreach ( $key in $Params.Keys.Clone()  ) {
        if ( -not $Params[$key]) { $Params.Remove($key) }
    }

    return Invoke-VSARestMethod @Params
}
New-Alias -Name Get-VSACustomFields -Value Get-VSACustomField
Export-ModuleMember -Function Get-VSACustomField -Alias Get-VSACustomFields