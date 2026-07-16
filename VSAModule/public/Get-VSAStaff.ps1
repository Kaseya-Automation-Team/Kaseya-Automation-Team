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
    .PARAMETER StaffId
        Specifies Staff ID to return.
    .PARAMETER OrganizationId
        Specifies Organization ID to return staff that belong to.
    .PARAMETER DepartmentId
        Specifies Department ID to return staff that belong to.
    .PARAMETER Filter.
        Specifies REST API Filter.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .PARAMETER Parallel
        Fetches the remaining pages of a large collection concurrently instead of one after another.
        Opt-in: without it, behaviour is unchanged. Results are identical either way (same records,
        merged in $skip order). Only engages once the collection is large enough to be worth it
        (see -ParallelThreshold).
    .PARAMETER ThrottleLimit
        Maximum number of concurrent requests when -Parallel is used (default 8). On shared SaaS you
        are one tenant among many, so a modest value is a good citizen; the engine also reduces
        concurrency automatically if the server returns HTTP 429, then recovers.
    .PARAMETER ParallelThreshold
        Minimum total record count before -Parallel actually engages. 0 (default) means automatic:
        two full throttle windows, i.e. 2 * ThrottleLimit * 100 records. Below that the sequential
        path is used, because it is faster than paying to set up extra connections.    .EXAMPLE
       Get-VSAStaff
    .EXAMPLE
       Get-VSAStaff -OrganizationId 10001
    .EXAMPLE
       Get-VSAStaff -DepartmentId 20002 -VSAConnection $connection
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

            ParameterSetName = 'Staff')]
        [parameter(Mandatory = $false,

            ParameterSetName = 'Department')]
        [parameter(Mandatory = $false,

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
        [string] $OrganizationId,

        [parameter(Mandatory = $false,
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
            ParameterSetName = 'Staff')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $StaffId,

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
        [string] $Sort,

        # Opt-in parallel paging for large collections (see Invoke-VSARestMethod). No effect on small
        # ones: below -ParallelThreshold the sequential path is used.
        [parameter(Mandatory = $false)]
        [switch] $Parallel,

        [parameter(Mandatory = $false)]
        [ValidateRange(1, 64)]
        [int] $ThrottleLimit = 8,

        [parameter(Mandatory = $false)]
        [ValidateRange(0, [int]::MaxValue)]
        [int] $ParallelThreshold = 0
        )
    process {

        $ItemId = [string]::Empty

        if( -not [string]::IsNullOrEmpty($OrganizationId)) {
            $URISuffix = "$URISuffix/orgs/{0}/staff"
            $ItemId = $OrganizationId
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

        $LogMsg | Write-Verbose

        [hashtable]$Params = @{
            URISuffix     = $( $URISuffix -f $ItemId )
            VSAConnection = $VSAConnection
            Filter        = $Filter
            Sort          = $Sort
        }

        foreach ( $key in @($Params.Keys)  ) {
            if ( -not $Params[$key]) { $Params.Remove($key) }
        }

        #region messages to verbose and debug streams
        "Get-VSAStaff: $($Params | Out-String)" | Write-Debug

        "Get-VSAStaff: $($Params | Out-String)" | Write-Verbose

        #endregion messages to verbose and debug streams

    # Forward the opt-in parallel controls to the shared read path, which owns the paging engine.
    if ($Parallel) {
        $Params['Parallel']      = $true
        $Params['ThrottleLimit'] = $ThrottleLimit
        if ($ParallelThreshold -gt 0) { $Params['ParallelThreshold'] = $ParallelThreshold }
    }
        return Invoke-VSARestMethod @Params
    }
}
Export-ModuleMember -Function Get-VSAStaff
