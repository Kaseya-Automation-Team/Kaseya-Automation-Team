function Disable-VSATenant
{
    <#
    .Synopsis
       Deactivates a tenant partition instead of deleting it.
    .DESCRIPTION
       Deactivates a tenant partition instead of deleting it.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER TenantName
        Specifies the Tenant Name.
    .PARAMETER TenantId
        Specifies the Tenant Id.
    .EXAMPLE
       Disable-VSATenant -TenantName 'TenantToDeactivate'
    .EXAMPLE
       Disable-VSATenant -TenantId 10001 -VSAConnection $connection
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

        [parameter(DontShow, Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ByName')]
        [parameter(DontShow, Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ById')]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/tenantmanagement/tenant/deactivate?tenantId={0}',

        [Parameter(Mandatory = $true,
        ValueFromPipelineByPropertyName = $true,
        ParameterSetName = 'ById')]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $TenantId
    )
     DynamicParam {
            $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            
            [hashtable] $AuxParameters = @{}
            if($VSAConnection) {$AuxParameters.Add('VSAConnection', $VSAConnection)}

            [array] $script:RoleTenants = Get-VSATenants @AuxParameters | Select-Object Id, @{N = 'TenantName'; E={$_.Ref}}

            $ParameterName = 'TenantName' 
            $AttributesCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
            $ParameterAttribute.Mandatory = $true
            $ParameterAttribute.ParameterSetName = 'ByName'
            $AttributesCollection.Add($ParameterAttribute)
            [string[]] $ValidateSet = $script:RoleTenants | Select-Object -ExpandProperty TenantName
            $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ValidateSet)
            $AttributesCollection.Add($ValidateSetAttribute)
            $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string[]], $AttributesCollection)
            $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)

            return $RuntimeParameterDictionary
        #}
    }# DynamicParam
    Begin {
        if ( -not $TenantId ) {
            $TenantId = $script:RoleTenants | Where-Object {$_.TenantName -eq $($PSBoundParameters.TenantName ) } | Select-Object -ExpandProperty Id
        }
    }# Begin
    Process {

        [hashtable]$Params = @{
            'URISuffix' = $($URISuffix -f $TenantId)
            'Method'    = 'DELETE'
        }
        if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

        #region messages to verbose and debug streams
        if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
            "Disable-VSATenant: $($Params | Out-String)" | Write-Debug
        }
        if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
            "Disable-VSATenant: $($Params | Out-String)" | Write-Verbose
        }
        #endregion messages to verbose and debug streams

        return Invoke-VSARestMethod @Params
    }
}
Export-ModuleMember -Function Disable-VSATenant