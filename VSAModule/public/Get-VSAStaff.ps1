function Get-VSAStaff
{
    <#
    .Synopsis
       Returns Staff.
    .DESCRIPTION
       Returns Staff.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER StaffID
        Specifies Staff ID to return.
    .PARAMETER OrganizationID
        Specifies Organization ID to return staff that belong to.
    .PARAMETER DepartmentID
        Specifies Department ID to return staff that belong to.
    .PARAMETER Filter.
        Specifies REST API Filter.
    .PARAMETER Paging
        Specifies REST API Paging.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .PARAMETER ResolveIDs
        Return Organizations' info as well as their respective IDs.
    .EXAMPLE
       Get-VSAStaff
    .EXAMPLE
       Get-VSAStaff -OrganizationID 10001
    .EXAMPLE
       Get-VSAStaff -DepartmentID 20002 -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Array of objects that represent Returns Staff.
    #> 
    [CmdletBinding(DefaultParameterSetName = 'Staff')] 
    param ( 
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Staff')]
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Department')] 
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Organization')]
        [ValidateNotNull()] 
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Staff')]
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Department')] 
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Organization')]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/system',
 
        [parameter(Mandatory=$true, 
            ValueFromPipelineByPropertyName=$true, 
            ParameterSetName = 'Organization')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $OrganizationID, 
 
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Department')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $DepartmentID,

        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Staff')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $StaffID,
 
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Staff')]
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Department')] 
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Organization')] 
        [string] $Filter,

        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Staff')]
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Department')] 
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Organization')] 
        [string] $Paging,

        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Staff')]
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Department')] 
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Organization')]
        [string] $Sort,
      
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Staff')]
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Department')] 
        [parameter(Mandatory = $false,  
            ValueFromPipelineByPropertyName = $true, 
            ParameterSetName = 'Organization')]
        [switch] $ResolveIDs
        )

        [string] $ItemId = ''

        if( -not [string]::IsNullOrEmpty($OrganizationID)) {
            $URISuffix = "$URISuffix/orgs/{0}/staff"
            $ItemId = $OrganizationID
            "Look for staff in the organization" | Write-Verbose
        }

        if( -not [string]::IsNullOrEmpty($DepartmentId)) {
            $URISuffix = "$URISuffix/departments/{0}/staff"
            $ItemId = $DepartmentId
            "Look for staff in the department" | Write-Verbose
        }

        if( -not [string]::IsNullOrEmpty($StaffId)) {
            $URISuffix = "$URISuffix/staff/{0}"
            $ItemId = $StaffId
            "Look for specific staff id" | Write-Verbose
        }

        if( [string]::IsNullOrEmpty($DepartmentId) -and [string]::IsNullOrEmpty($StaffId) -and [string]::IsNullOrEmpty($OrganizationID)) {
            $URISuffix = "$URISuffix/staff"
            "Look for all staff" | Write-Verbose
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
Export-ModuleMember -Function Get-VSAStaff