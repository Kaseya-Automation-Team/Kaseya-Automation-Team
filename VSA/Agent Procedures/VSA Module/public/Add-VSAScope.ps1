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
    [CmdletBinding(SupportsShouldProcess)]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/system/scopes',

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $ScopeName
    )

    $Body = @{'ScopeName'= $ScopeName } | ConvertTo-Json

    [hashtable]$Params =@{
        URISuffix      = $URISuffix
        Method         = 'POST'
        Body           = $Body
    }
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    $Params | Out-String | Write-Debug

    if( $PSCmdlet.ShouldProcess( $ScopeName ) ) {

        $Result = Update-VSAItems @Params

        $Result | Out-String | Write-Verbose
        $Result | Out-String | Write-Debug
    }
    return $Result
}
Export-ModuleMember -Function Add-VSAScope