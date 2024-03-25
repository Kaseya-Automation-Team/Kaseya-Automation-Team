function Remove-VSAOrganization {
    <#
    .Synopsis
       Removes an organization.
    .DESCRIPTION
       Removes an organization.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER OrgId
        Id of the organization to remove.
    .EXAMPLE
       Remove-VSAOrganization -OrgId 10001
    .EXAMPLE
       Remove-VSAOrganization -OrgId 10001 -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if removing was successful.
    #>
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High'
    )]
    param (
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = 'api/v1.0/system/orgs/{0}',

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName=$true,
            HelpMessage = "Numeric ID of Organization to be removed.")]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $OrgId
        )

    $URISuffix = $URISuffix -f $OrgId

    [bool]$result = $false

    [hashtable]$Params = @{}
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    $Params.Add('URISuffix', $URISuffix)
    $Params.Add('Method', 'DELETE')

    if( $PSCmdlet.ShouldProcess( $OrgId ) ) {
        return Update-VSAItems @Params
    }
    
}
Export-ModuleMember -Function Remove-VSAOrganization