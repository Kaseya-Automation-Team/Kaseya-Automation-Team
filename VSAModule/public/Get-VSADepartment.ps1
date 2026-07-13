function Get-VSADepartment
{
    <#
    .Synopsis
       Returns Department Data.
    .DESCRIPTION
       Returns Department Data.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies a non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER OrgID
        Specifies Organization ID.
        Not Compatible with -DepartmentId parameter.
    .PARAMETER DepartmentId
        Specifies Department Id.
        Not Compatible with -OrgID parameter.
    .PARAMETER Filter
        Specifies REST API Filter.
    .PARAMETER Sort
        Specifies REST API Sorting.
    .EXAMPLE
       Get-VSADepartment -OrgID 10001 -VSAConnection $VSAConnection
    .EXAMPLE
       Get-VSADepartment -DepartmentId 10001 -VSAConnection $VSAConnection
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       Array of objects that represent Departments' Data.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Department')]
    param (

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Organization')]
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Department')]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false,

            ParameterSetName = 'Organization')]
        [parameter(DontShow, Mandatory = $false,

            ParameterSetName = 'Department')]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Organization')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $OrgId,

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
        [string] $Sort
    )
    process {

    $ItemId  = [string]::Empty
    $Message = [string]::Empty

    if ( -not [string]::IsNullOrEmpty($OrgId) ) {
        #Departments for a specific organization
        if( [string]::IsNullOrEmpty($URISuffix) ) { $URISuffix = "api/v1.0/system/orgs/{0}/departments" }
        $ItemId = $OrgId
        $Message = "Look for departments in the Organization with ID: '$ItemId'"
    } else {
        #Specific department
        if( [string]::IsNullOrEmpty($URISuffix) ) { $URISuffix= "api/v1.0/system/departments/{0}" }
        $ItemId = $DepartmentId
        $Message = "Look for the Department with ID: '$ItemId'"
    }
    $URISuffix = $URISuffix -f $ItemId

    #region messages to verbose and debug streams
    $Message | Write-Debug

    $Message | Write-Verbose

    #endregion messages to verbose and debug streams

    [hashtable]$Params = @{
        VSAConnection = $VSAConnection
        URISuffix     = $URISuffix
        Filter        = $Filter
        Sort          = $Sort
    }

    #Remove empty keys
    foreach ( $key in @($Params.Keys)  ) {
        if ( -not $Params[$key]) { $Params.Remove($key) }
    }

    $Message = "$($MyInvocation.MyCommand.Name):`n$($Params | Out-String)"

    #region messages to verbose and debug streams
    $Message | Write-Debug

    $Message | Write-Verbose

    #endregion messages to verbose and debug streams

    return Invoke-VSARestMethod @Params
    }
}
Export-ModuleMember -Function Get-VSADepartment
