function Get-VSAMachineGroup
{
    <#
    .Synopsis
       Returns Machine Groups.
    .DESCRIPTION
       Returns Machine Groups.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER MachineGroupID
        Specifies MachineGroupID to return. All Machine Groups are returned if MachineGroupID not specified.
    .PARAMETER Filter
        Specifies REST API Filter.
    .PARAMETER Paging
        Specifies REST API Paging.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .PARAMETER ResolveIDs
        Return Organizations' info as well as their respective IDs.
    .EXAMPLE
       Get-VSAMachineGroup
    .EXAMPLE
       Get-VSAMachineGroup -MachineGroupID '10001' -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Array of objects that represent Machine Groups.
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/system/machinegroups',

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $MachineGroupID,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Paging,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort,

        [Parameter(Mandatory = $false)]
        [switch] $ResolveIDs
    )

    if( -not [string]::IsNullOrEmpty($MachineGroupID)) {
        $URISuffix = "$URISuffix/$MachineGroupID"
    }

    [hashtable]$Params = @{}
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    $Params.Add('URISuffix', $URISuffix)
    if($Filter)        {$Params.Add('Filter', $Filter)}
    if($Paging)        {$Params.Add('Paging', $Paging)}
    if($Sort)          {$Params.Add('Sort', $Sort)}

    $Params | Out-String | Write-Verbose
    $Params | Out-String | Write-Debug

    $result = Get-VSAItems @Params

    if ($ResolveIDs)
    {
        [hashtable]$ResolveParams =@{}
        if($VSAConnection) {$ResolveParams.Add('VSAConnection', $VSAConnection)}

        [hashtable]$OrganizationDictionary = @{}

        Foreach( $Organization in $(Get-VSAOrganization @ResolveParams) )
        {
            if ( -Not $OrganizationDictionary[$Organization.OrgId]) {
                $OrganizationDictionary.Add($Organization.OrgId, $($Organization | Select-Object * -ExcludeProperty OrgId))
            }
        }

        $result = $result | Select-Object -Property *, `
            @{Name = 'Organization'; Expression = { $OrganizationDictionary[$_.OrgId] }}
    }
    
    return $result
}
Export-ModuleMember -Function Get-VSAMachineGroup