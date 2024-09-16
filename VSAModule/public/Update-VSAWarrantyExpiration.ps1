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
    .PARAMETER AgentId
        Specifies id of the agent machine.
    .PARAMETER PurchaseDate
        Specifies date of the purchase.
    .PARAMETER WarrantyExpireDate
        Specifies warranty expiration date.
    .EXAMPLE
        Update-VSAWarrantyExpiration -AgentID 3324234234 -PurchaseDate "2021-10-21T10:00:00.000Z" -WarrantyExpireDate "2022-10-21T10:00:00.000Z"
    .EXAMPLE
       Update-VSAWarrantyExpiration -VSAConnection $connection -AgentID 3324234234 -PurchaseDate "2021-10-21T10:00:00.000Z" -WarrantyExpireDate "2022-10-21T10:00:00.000Z"
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Success or failure.
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
        [string] $AgentID,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $PurchaseDate,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $WarrantyExpireDate
    )

    [hashtable]$Params = @{
        URISuffix = $($URISuffix -f $AgentID)
        Body      = "{`"PurchaseDate`":`"$PurchaseDate`",`"WarrantyExpireDate`":`"$WarrantyExpireDate`"}"
        Method    = 'PUT'
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}
Export-ModuleMember -Function Update-VSAWarrantyExpiration