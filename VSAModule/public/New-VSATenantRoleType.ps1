function New-VSATenantRoleType
{
    <#
    .Synopsis
       Adds a roletype.
    .DESCRIPTION
       Creates a new roletype.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER Name
        Specifies the Role Name.
    .PARAMETER Description
        Specifies the Role Description.
    .PARAMETER AdminGroupType
        Specifies Id of Admin Group Type.
    .PARAMETER HasUserData
        Specifies if Has User Data.
    .EXAMPLE
       New-VSATenantRoleType -Name 'A New Role'
    .EXAMPLE
       New-VSATenantRoleType -Name 'A New Role' -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if creation was successful.
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/tenantmanagement/roletypes',

        [Parameter(Mandatory = $true,
        ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Parameter(Mandatory = $false,
        ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $Status,

        [Parameter(Mandatory = $false,
        ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Description,

        [Parameter(Mandatory = $false,
        ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( (-not [string]::IsNullOrEmpty($_)) -and ($_ -notmatch "^\d+$") ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AdminGroupType,

        [Parameter(Mandatory = $false,
        ValueFromPipelineByPropertyName = $true)]
        [ValidateSet("Y", "N")]
        [string] $HasUserData
    )
    [hashtable] $AuxParameters = @{}
    if($VSAConnection) {$AuxParameters.Add('VSAConnection', $VSAConnection)}
    [int] $Zzvalsid  = try {(Get-VSATenantRoletypesFunclists @AuxParameters | Select-Object -ExpandProperty Zzvalsid | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum) + 1} catch {throw $_}
    [string] $Zzvals = "zzvals$Zzvalsid"

    $BodyHT = [ordered] @{
                    Name     = $Name
                    Zzvalsid = $Zzvalsid
                    Zzvals   = $Zzvals
                }
    if ( -not [string]::IsNullOrEmpty($Status))         {$BodyHT.Add('Status', $Status) }
    if ( -not [string]::IsNullOrEmpty($Description))    {$BodyHT.Add('Description', $Description) }
    if ( -not [string]::IsNullOrEmpty($AdminGroupType)) {$BodyHT.Add('AdminGroupType', $AdminGroupType) }
    if ( -not [string]::IsNullOrEmpty($HasUserData))    {$BodyHT.Add('HasUserData', $HasUserData) }
    
    [string]$Body = $BodyHT| ConvertTo-Json

    [hashtable]$Params =@{
        URISuffix      = $URISuffix
        Method         = 'POST'
        Body           = $Body
    }
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}
New-Alias -Name Add-VSATenantRoleType -Value New-VSATenantRoleType
Export-ModuleMember -Function New-VSATenantRoleType -Alias Add-VSATenantRoleType