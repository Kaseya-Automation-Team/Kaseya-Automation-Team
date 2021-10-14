function Add-VSATenantRoleType
{
    <#
    .Synopsis
       Adds a roletype.
    .DESCRIPTION
       Adds a roletype.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER RoleName
        Specifies the Role Name.
    .PARAMETER Description
        Specifies the Role Description.
    .PARAMETER AdminGroupType
        Specifies Id of Admin Group Type.
    .PARAMETER HasUserData
        Specifies if Has User Data.
    .EXAMPLE
       Add-VSATenantRoleType -RoleName 'A New Role'
    .EXAMPLE
       Add-VSATenantRoleType -RoleName 'A New Role' -VSAConnection $connection
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

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/tenantmanagement/roletypes',

        [Parameter(Mandatory = $true,
        ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $RoleName,

        [Parameter(Mandatory = $false,
        ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $Description,

        [Parameter(Mandatory = $false,
        ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
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
    [int] $Zzvalsid  = try {(Get-VSATenantRoletypesFunclists | Select-Object -ExpandProperty Zzvalsid | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum) + 1} catch {throw $_}
    [string] $Zzvals = "zzvals$Zzvalsid"

    $BodyHT = [ordered] @{
                    Name     = $RoleName
                    Zzvalsid = $Zzvalsid
                    Zzvals   = $Zzvals
                }
    if ( -not [string]::IsNullOrEmpty($Description))    {$BodyHT.Add('Description', $Description) }
    if ( -not [string]::IsNullOrEmpty($AdminGroupType)) {$BodyHT.Add('AdminGroupType', $AdminGroupType) }
    if ( -not [string]::IsNullOrEmpty($HasUserData))    {$BodyHT.Add('HasUserData', $HasUserData) }
    
    [string]$Body = $BodyHT| ConvertTo-Json

    [hashtable]$Params = @{}
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    $Params.Add('URISuffix', $URISuffix)
    $Params.Add('Method', 'POST')
    $Params.Add('Body', $Body)

    return Update-VSAItems @Params
}
Export-ModuleMember -Function Add-VSATenantRoleType