function Update-VSADepartment
{
    <#
    .Synopsis
       Updates an existing department.
    .DESCRIPTION
       Updates an existing department info.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER DepartmentName
        Specifies the Department Name.
    .PARAMETER ParentDepartmentId
        Specifies the Parent Department Id.
    .PARAMETER ManagerId
        Specifies the Manager Id.
    .EXAMPLE
       Update-VSADepartment -ParentDepartmentId 10001 -DepartmentName 'A New Department Name'
    .EXAMPLE
       Update-VSADepartment -ParentDepartmentId 10001 -DepartmentName 'A New Department Name' -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if update was successful.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/system/departments/{0}',

        [Parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $DepartmentId,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $DepartmentName,

        [Parameter(Mandatory = $false)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $ParentDepartmentId,

        [Parameter(Mandatory = $false)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $ManagerId
    )
    process {

    [hashtable]$BodyHT =    @{}
    if ($DepartmentName)     { $BodyHT.Add('DepartmentName', $DepartmentName) }
    if ($ParentDepartmentId) { $BodyHT.Add('ParentDepartmentId', $ParentDepartmentId) }
    if ($ManagerId)          { $BodyHT.Add('ManagerId', $ManagerId) }
    
    if ( 0 -eq $BodyHT.Count) {
        throw "No changes specified to the Department $DepartmentId"
    }

    return Invoke-VSAWriteRequest -Body ($($BodyHT | ConvertTo-Json)) -Method 'PUT' -URISuffix ($($URISuffix -f $DepartmentId)) -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function Update-VSADepartment