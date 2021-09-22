function Add-VSAScope
{
    <#
    .Synopsis
       Creates a new scope.
    .DESCRIPTION
       Creates a new VSA scope.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER ScopeName
        Specifies the Scope Name.
    .EXAMPLE
       Add-VSAScope -ScopeName 'ANewScope'
    .EXAMPLE
       Add-VSAScope -ScopeName 'ANewScope' -VSAConnection $connection
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
        [string] $URISuffix = 'api/v1.0/system/scopes',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ScopeName
    )

    $Body = @{'ScopeName'= $ScopeName } | ConvertTo-Json

    [hashtable]$Params = @{}
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    $Params.Add('URISuffix', $URISuffix)
    $Params.Add('Method', 'POST')
    $Params.Add('Body', $Body)

    return Update-VSAItems @Params
}
Export-ModuleMember -Function Add-VSAScope