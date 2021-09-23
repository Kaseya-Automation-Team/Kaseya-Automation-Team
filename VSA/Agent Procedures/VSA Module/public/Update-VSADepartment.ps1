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
       Update-VSADepartment -OrganizationId 10001 -DepartmentName 'A New Department Name'
    .EXAMPLE
       Update-VSADepartment -OrganizationId 10001 -DepartmentName 'A New Department Name' -VSAConnection $connection
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
    $URISuffix = $URISuffix -f $DepartmentId

    [hashtable]$BodyHT =    @{}
    if ($DepartmentName)     { $BodyHT.Add('DepartmentName', $DepartmentName) }
    if ($ParentDepartmentId) { $BodyHT.Add('ParentDepartmentId', $ParentDepartmentId) }
    if ($ManagerId)          { $BodyHT.Add('ManagerId', $ManagerId) }

    $Body = $BodyHT | ConvertTo-Json
    $Body | Out-String | Write-Debug

    [hashtable]$Params = @{}
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    $Params.Add('URISuffix', $URISuffix)
    $Params.Add('Method', 'PUT')
    $Params.Add('Body', $Body)

    return Update-VSAItems @Params
}
Export-ModuleMember -Function Update-VSADepartment