function Get-VSAModuleActivated {
    <#
    .Synopsis
       Returns true or false, based on whether the specified module ID is activated.
    .DESCRIPTION
       Returns true or false, based on whether the specified module ID is activated.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER ModuleId
        Specifies module Id
    .EXAMPLE
       Get-VSAModuleActivated -ModuleId 10001
    .EXAMPLE
       Get-VSAModuleActivated -ModuleId 10001 -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Returns true or false, based on whether the specified module ID is activated.
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/ismoduleactivated/{0}',

        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric value"
            }
            return $true
        })]
        [string] $ModuleId
    )

    $URISuffix = $URISuffix -f $ModuleId

    [hashtable]$Params =@{
        URISuffix = $URISuffix
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Get-VSAItems @Params
}

Export-ModuleMember -Function Get-VSAModuleActivated