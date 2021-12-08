function Add-VSADepartment
{
    <#
    .Synopsis
       Creates a new Department.
    .DESCRIPTION
       Creates a new Department in an existing organization.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER OrgId
        Specifies the Organization Id.
    .PARAMETER DepartmentName
        Specifies the Department Name.
    .PARAMETER ParentDepartmentId
        Specifies the Parent Department Id.
    .PARAMETER ManagerId
        Specifies the Manager Id.
    .EXAMPLE
       Add-VSADepartment -OrgId 10001 -DepartmentName 'A New Department'
    .EXAMPLE
       Add-VSADepartment -OrgId 10001 -DepartmentName 'A New Department' -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if creation was successful.
       ID of new Department if the ExtendedOutput switch specified.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/system/orgs/{0}/departments',

        [Parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $OrgId,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $DepartmentName,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $ParentDepartmentId,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $DepartmentRef,

        [Parameter(Mandatory = $false)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $ManagerId,

        [parameter(DontShow,
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $Attributes,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [switch] $ExtendedOutput
    )
    $URISuffix = $URISuffix -f $OrgId

    [hashtable]$BodyHT =    @{ DepartmentName = $DepartmentName}
    if ($ParentDepartmentId) { $BodyHT.Add('ParentDepartmentId', $ParentDepartmentId) }
    if ($ManagerId)          { $BodyHT.Add('ManagerId', $ManagerId) }
    if ($DepartmentRef)      { $BodyHT.Add('DepartmentRef', $DepartmentRef) }

    if ( -not [string]::IsNullOrEmpty($Attributes) ) {
        [hashtable] $AttributesHT = ConvertFrom-StringData -StringData $Attributes
        $BodyHT.Add('Attributes', $AttributesHT )
    }

    $Body = $BodyHT | ConvertTo-Json
    $Body | Out-String | Write-Debug

    [hashtable]$Params =@{
                            URISuffix      = $URISuffix
                            Method         = 'POST'
                            Body           = $Body
                            ExtendedOutput = $ExtendedOutput
                        }
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    $Result = Update-VSAItems @Params
    $Result | Out-String | Write-Verbose
    $Result | Out-String | Write-Debug

    if ($ExtendedOutput) { $Result = $Result | Select-Object -ExpandProperty Result }
    return $Result
}
Export-ModuleMember -Function Add-VSADepartment