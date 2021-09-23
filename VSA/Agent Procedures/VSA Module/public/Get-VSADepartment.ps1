function Get-VSADepartment
{
    <#
    .Synopsis
       Returns Organizations Data.
    .DESCRIPTION
       Returns Organizations Data.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER OrganizationID
        Specifies Organization ID.
        Not Compatible with -DepartmentId parameter.
    .PARAMETER DepartmentId
        Specifies Department Id.
        Not Compatible with -OrganizationID parameter.
    .PARAMETER Filter
        Specifies REST API Filter.
    .PARAMETER Paging
        Specifies REST API Paging.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .EXAMPLE
       Get-VSADepartment -OrganizationID 10001
    .EXAMPLE
       Get-VSADepartment -DepartmentId 10001 -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Array of objects that represent Departments' Data.
    #>
    [CmdletBinding()]
    param ( 
        
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Organization')] 
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Department')]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Organization')] 
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Department')]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/system',

        [Parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Organization')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $OrganizationId,

        [Parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Department')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $DepartmentId,

        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Organization')] 
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Department')]
        [ValidateNotNullOrEmpty()] 
        [string] $Filter,

        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Organization')] 
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Department')]
        [ValidateNotNullOrEmpty()] 
        [string] $Paging,

        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Organization')] 
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Department')]
        [ValidateNotNullOrEmpty()] 
        [string] $Sort
    )

    [string] $ItemId

    if( -not [string]::IsNullOrEmpty($OrganizationID)) {
        $URISuffix = "$URISuffix/orgs/{0}/departments"
        $ItemId = $OrganizationID
        "Look for departments in the organization" | Write-Verbose
    }

    if( -not [string]::IsNullOrEmpty($DepartmentId)) {
        $URISuffix = "$URISuffix/departments/{0}"
        $ItemId = $DepartmentId
        "Look for specific department" | Write-Verbose
    }


    $URISuffix = $URISuffix -f $ItemId
    $URISuffix | Write-Verbose
    $URISuffix | Write-Debug


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
Export-ModuleMember -Function Get-VSADepartment