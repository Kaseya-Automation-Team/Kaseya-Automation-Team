function Add-VSARole
{
    <#
    .Synopsis
       Adds new user role
    .DESCRIPTION
       Adds new user role in VSA with specified role type ids
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER RoleName
        Specifies name of the role
    .PARAMETER RoleTypeIds
        Specifies array of role type ids
    .EXAMPLE
       Add-VSARole -RoleName "Remote desktop" -RoleTypeIds 4, 6, 100, 101
    .EXAMPLE
       Add-VSARole -VSAConnection $connection -RoleName "Remote desktop" -RoleTypeIds 4, 6, 100, 101
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       No output
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/system/roles",

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $RoleName,

		[parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( 0 -ge $_.Count ) {
                throw "No value provided"
            }
            return $true
        })]
        [string[]] $RoleTypeIds,

        [parameter(DontShow,
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [string] $Attributes
)
    
    [hashtable]$BodyHT = @{  RoleName = $RoleName }

    $BodyHT.Add('RoleTypeIds', $RoleTypeIds )

    if ( -not [string]::IsNullOrEmpty($Attributes) ) {
        [hashtable] $AttributesHT = ConvertFrom-StringData -StringData $Attributes
        $BodyHT.Add('Attributes', $AttributesHT )
    }

    $Body = $BodyHT | ConvertTo-Json
    $Body | Write-Debug

    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'POST'
        Body = $Body
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    $Params | Out-String | Write-Debug

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Add-VSARole