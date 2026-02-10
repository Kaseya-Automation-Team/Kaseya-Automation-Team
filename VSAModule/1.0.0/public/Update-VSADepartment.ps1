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
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
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

    [hashtable]$BodyHT =    @{}
    if ($DepartmentName)     { $BodyHT.Add('DepartmentName', $DepartmentName) }
    if ($ParentDepartmentId) { $BodyHT.Add('ParentDepartmentId', $ParentDepartmentId) }
    if ($ManagerId)          { $BodyHT.Add('ManagerId', $ManagerId) }
    
    if ( 0 -eq $BodyHT.Count) {
        throw "No changes specified to the Department $DepartmentId"
    }

    [hashtable]$Params = @{
        URISuffix = $($URISuffix -f $DepartmentId)
        Method    = 'PUT'
        Body      = $($BodyHT | ConvertTo-Json)
    }
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}
Export-ModuleMember -Function Update-VSADepartment