function Delete-VSATenantRoleType
{
    <#
    .Synopsis
       Removes a roletype from the entire VSA.
    .DESCRIPTION
       Removes a roletype from the entire VSA.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER RoleTypeName
        Specifies the Role Type Name.
    .PARAMETER RoleTypeId
        Specifies the Role Type Id.
    .EXAMPLE
       Delete-VSATenantRoleType -RoleTypeName 'An Existing Role'
    .EXAMPLE
       Delete-VSATenantRoleType -RoleTypeId 10001 -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if successful.
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ByName')]
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ById')]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ByName')]
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/tenantmanagement/roletypes/{0}',

        [Parameter(Mandatory = $true,
        ValueFromPipelineByPropertyName = $true,
        ParameterSetName = 'ById')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $RoleTypeId
    )
     DynamicParam {

            $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            
            [hashtable] $AuxParameters = @{}
            if($VSAConnection) {$AuxParameters.Add('VSAConnection', $VSAConnection)}

            [array] $script:RoleTypes = Get-VSARoleTypes @AuxParameters | Select RoleTypeId, RoleTypeName

            $ParameterName = 'RoleTypeName' 
            $AttributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $true
            $ParameterAttribute.ParameterSetName = 'ByName'
            $AttributesCollection.Add($ParameterAttribute)
            [string[]] $ValidateSet = $script:RoleTypes | Select-Object -ExpandProperty RoleTypeName
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
            $AttributesCollection.Add($ValidateSetAttribute)
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string[]], $AttributesCollection)
            $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

            return $RuntimeParameterDictionary
        #}
    }# DynamicParam
    Begin {
        if ( -not $RoleTypeId ) {
            $RoleTypeId = $script:RoleTypes | Where-Object {$_.RoleTypeName -eq $($PSBoundParameters.RoleTypeName ) } | Select-Object -ExpandProperty RoleTypeId
        }
    }# Begin
    Process {
    $URISuffix = $URISuffix -f $RoleTypeId
    $URISuffix | Write-Debug
    

    [hashtable]$Params = @{
                            'URISuffix' = $URISuffix
                            'Method'    = 'DELETE'
    }
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    $Params | Out-String | Write-Debug

    return Update-VSAItems @Params
    }
}
Export-ModuleMember -Function Delete-VSATenantRoleType