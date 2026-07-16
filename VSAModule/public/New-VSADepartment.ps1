function New-VSADepartment
{
    <#
    .Synopsis
       Creates a new Department.
    .DESCRIPTION
       Creates a new Department in an existing organization.
    .PARAMETER VSAConnection
        Specifies a non-persistent VSAConnection.
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
    .PARAMETER DepartmentRef
        Specifies the short reference name of the department.
    .PARAMETER Attributes
        Specifies additional attributes to send in the request body.
    .PARAMETER ExtendedOutput
        Returns the full API response envelope instead of only the result set.
    .EXAMPLE
       Add-VSADepartment -OrgId 10001 -DepartmentName 'A New Department' -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if creation was successful.
       ID of new Department if the ExtendedOutput switch specified.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is invoked centrally by Invoke-VSAWriteRequest, which receives this cmdlet''s $PSCmdlet via -Caller (module-wide pattern).')]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
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
        # Accepts a [hashtable]/[pscustomobject] (preferred) or the legacy "Key=value" string.
        [object] $Attributes,

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [switch] $ExtendedOutput
    )
    process {
    $URISuffix = $URISuffix -f $OrgId

    [string[]]$AllFields  = @('DepartmentName', 'ParentDepartmentId', 'ManagerId', 'DepartmentRef')

    # Build the request body from bound parameters, preserving values exactly (F-39).
    [hashtable]$BodyHT = ConvertTo-VSARequestBody -BoundParameters $PSBoundParameters -Include $AllFields

    if ( $null -ne $Attributes ) {
        [hashtable] $AttributesHT = ConvertTo-VSAHashtable $Attributes
        if ( 0 -lt $AttributesHT.Count ) { $BodyHT['Attributes'] = $AttributesHT }
    }

    #Remove empty keys
    foreach ( $key in @($BodyHT.Keys) ) {
        if ( -not $BodyHT[$key] )  { $BodyHT.Remove($key) }
    }

    [string]$Body = $BodyHT | ConvertTo-Json
    Write-Debug "New-VSADepartment. Request Body: $Body"

    return Invoke-VSAWriteRequest -Body $Body -Method POST -URISuffix $URISuffix `
        -VSAConnection $VSAConnection -ExtendedOutput:$ExtendedOutput -Caller $PSCmdlet
    }
}
New-Alias -Name Add-VSADepartment -Value New-VSADepartment
Export-ModuleMember -Function New-VSADepartment -Alias Add-VSADepartment