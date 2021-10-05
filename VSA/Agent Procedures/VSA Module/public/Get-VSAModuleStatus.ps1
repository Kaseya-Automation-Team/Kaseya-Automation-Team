function Get-VSAModuleStatus {
    <#
    .Synopsis
       Check if specific module is installed.
    .DESCRIPTION
       Returns true or false, based on whether the specified module ID is installed.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .EXAMPLE
       Get-VSAModuleStatus -ModuleId 3
    .EXAMPLE
       Get-VSAModuleStatus -VSAConnection $connection -ModuleId 3
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True of False
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
        [string] $URISuffix = 'api/v1.0/ismoduleinstalled/{0}',
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $ModuleId
    )

    $URISuffix = $URISuffix -f $ModuleId

    [hashtable]$Params =@{
        URISuffix = $URISuffix
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Get-VSAItems @Params
}

Export-ModuleMember -Function Get-VSAModuleStatus