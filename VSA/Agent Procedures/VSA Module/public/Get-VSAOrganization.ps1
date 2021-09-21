function Get-VSAOrganization
{
    <#
    .Synopsis
       Returns Organizations.
    .DESCRIPTION
       Returns Organizations.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER OrganizationID
        Specifies OrganizationID to return. All Organizations are returned if no OrganizationID specified.
    .PARAMETER Filter
        Specifies REST API Filter.
    .PARAMETER Paging
        Specifies REST API Paging.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .EXAMPLE
       Get-VSAOrganization 
    .EXAMPLE
       Get-VSAOrganization -OrganizationID '10001' -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Array of objects that represent Organizations.
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/system/orgs',

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $OrganizationID,

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

    if( -not [string]::IsNullOrEmpty($OrganizationID)) {
        $URISuffix = "$URISuffix/$OrganizationID"
    }

    [hashtable]$Params = @{}
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    $Params.Add('URISuffix', $URISuffix)
    if($Filter)        {$Params.Add('Filter', $Filter)}
    if($Paging)        {$Params.Add('Paging', $Paging)}
    if($Sort)          {$Params.Add('Sort', $Sort)}

    $Params | Out-String | Write-Verbose
    $Params | Out-String | Write-Debug

    return Get-VSAItems @Params
}
Export-ModuleMember -Function Get-VSAOrganization