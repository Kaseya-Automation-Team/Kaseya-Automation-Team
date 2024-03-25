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

        [parameter(DontShow, Mandatory=$false,
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

    [hashtable]$BodyHT = ($(Get-PSCallStack)[0].Arguments).Trim('{}') -replace ',', "`n" | ConvertFrom-StringData

    [string[]]$AllFields  = @('DepartmentName', 'ParentDepartmentId', 'ManagerId', 'DepartmentRef', 'Attributes')

    foreach ( $key in $BodyHT.Keys.Clone() ) {
        if ( $key -notin $AllFields )  { $BodyHT.Remove($key) }
    }

    if ( -not [string]::IsNullOrEmpty($Attributes) ) {
        [hashtable] $AttributesHT = ConvertFrom-StringData -StringData $Attributes
        $BodyHT['Attributes'] = $AttributesHT
    }

    #Remove empty keys
    foreach ( $key in $BodyHT.Keys.Clone() ) {
        if ( -not $BodyHT[$key] )  { $BodyHT.Remove($key) }
    }

    [string]$Body = $BodyHT | ConvertTo-Json
    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        Write-Debug "New-VSADepartment. Request Body: $Body"
    }

    

    [hashtable]$Params =@{
        VSAConnection  = $VSAConnection
        URISuffix      = $URISuffix
        Method         = 'POST'
        Body           = $Body
        ExtendedOutput = $ExtendedOutput
    }
    #Remove empty keys
    foreach ( $key in $Params.Keys.Clone() ) {
        if ( -not $Params[$key] )  { $Params.Remove($key) }
    }

    $Result = Invoke-VSARestMethod @Params

    if ($ExtendedOutput) { $Result = $Result | Select-Object -ExpandProperty Result }
    return $Result
}
New-Alias -Name Add-VSADepartment -Value New-VSADepartment
Export-ModuleMember -Function New-VSADepartment -Alias Add-VSADepartment