function Update-VSAThirdApp
{
    <#
    .Synopsis
       Enables or disables third party apps in a tenant.
    .DESCRIPTION
       Enables or disables third party apps in a tenant.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER Id
        Specifies id of the tenant
    .PARAMETER Enable
        Specifies if third party apps should be enabled
    .PARAMETER Disable
        Specifies if third party apps should be disabled
    .EXAMPLE
       Update-VSAThirdApp -Id 979868787875855 -Enable
    .EXAMPLE
       Update-VSAThirdApp -Id 979868787875855 -Disable
    .EXAMPLE
       Update-VSAThirdApp -VSAConnection $connection -Id 979868787875855 -Enable
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Success or failure
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'NonPersistent')]
        [VSAConnection] $VSAConnection,
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'NonPersistent')]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'Persistent')]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/thirdpartyapps/{0}/status/{1}",
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Id,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [switch] $Enable = $false,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [switch] $Disable = $false
)
	
    if (!$Enable -and !$Disable) {
        throw 'Single switch "Enabled" or "Disabled" should be provided.'
    }

    if ($Enable -and $Disable) {
        throw 'Only one switch "Enabled" or "Disabled" can be provided at the same time.'
    }

    if ($Enable -and ($Disable -eq $false)) {
        $EnableOrDisable = "true"
    }

    if ($Disable -and ($Enable -eq $false)) {
        $EnableOrDisable = "false"
    }

    $URISuffix = $URISuffix -f $Id, $EnableOrDisable

    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'PUT'
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Update-VSAThirdApp