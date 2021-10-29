function Update-VSAWarrantyExpiration
{
    <#
    .Synopsis
       Updates the purchase date and warranty expiration date for a single agent.
    .DESCRIPTION
       Updates the purchase date and warranty expiration date for a single agent.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .EXAMPLE
       Update-VSAWarrantyExpiration -AgentID 10001
    .EXAMPLE
       Update-VSAWarrantyExpiration -AgentID 10001 -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if start of baseline audit was successful.
    #>
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/assetmgmt/audit/{0}/hardware/purchaseandwarrantyexpire', 
 
        [parameter(Mandatory = $true,  
            ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentID
    )
    
    $URISuffix = $URISuffix -f $AgentID

    [hashtable]$Params = @{
        URISuffix = $($URISuffix -f $AgentID)
        Method = 'PUT'
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Update-VSAItems @Params
}
Export-ModuleMember -Function Update-VSAWarrantyExpiration