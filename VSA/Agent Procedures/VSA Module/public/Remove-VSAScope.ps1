function Remove-VSAScope
{
    <#
    .Synopsis
       Removes an existing scope.
    .DESCRIPTION
       Removes an existing VSA scope.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER ScopeId
        Specifies the Scope Id to remove.
    .EXAMPLE
       Remove-VSAScope -ScopeId 10001
    .EXAMPLE
       Remove-VSAScope -ScopeId 10001 -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if removing was successful.
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
        [string] $URISuffix = 'api/v1.0/system/scopes/{0}',

        [Parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Numeric ID of Scope to be removed.")]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $ScopeId
    )

    $URISuffix = $URISuffix -f $ScopeId

    [hashtable]$Params = @{}
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    $Params.Add('URISuffix', $URISuffix)
    $Params.Add('Method', 'DELETE')

    return Update-VSAItems @Params
}
Export-ModuleMember -Function Remove-VSAScope