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
        [string] $Sort
        )

        $ItemId = [string]::Empty

        if( -not [string]::IsNullOrEmpty($OrganizationID)) {
            $URISuffix = "$URISuffix/orgs/{0}/staff"
            $ItemId = $OrganizationID
            $LogMsg = "Look for staff in the organization: $ItemId"
        }

        if( -not [string]::IsNullOrEmpty($DepartmentId)) {
            $URISuffix = "$URISuffix/departments/{0}/staff"
            $ItemId = $DepartmentId
            $LogMsg = "Look for staff in the department: $ItemId"
        }

        if( -not [string]::IsNullOrEmpty($StaffId)) {
            $URISuffix = "$URISuffix/staff/{0}"
            $ItemId = $StaffId
            $LogMsg = "Look for specific staff id: $ItemId"
        }

        if( [string]::IsNullOrEmpty($DepartmentId) -and [string]::IsNullOrEmpty($StaffId) -and [string]::IsNullOrEmpty($OrganizationID)) {
            $URISuffix = "$URISuffix/staff"
            $LogMsg = "Look for all staff"
        }

        if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
            $LogMsg | Write-Verbose
        }

        [hashtable]$Params = @{
            URISuffix     = $( $URISuffix -f $ItemId )
            VSAConnection = $VSAConnection
            Filter        = $Filter
            Paging        = $Paging
            Sort          = $Sort
        }

        foreach ( $key in $Params.Keys.Clone()  ) {
            if ( -not $Params[$key]) { $Params.Remove($key) }
        }

        #region messages to verbose and debug streams
        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
            "Get-VSAStaff: $($Params | Out-String)" | Write-Debug
        }
        if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
            "Get-VSAStaff: $($Params | Out-String)" | Write-Verbose
        }
        #endregion messages to verbose and debug streams
        
        return Invoke-VSARestMethod @Params
} 
Export-ModuleMember -Function Get-VSAStaff