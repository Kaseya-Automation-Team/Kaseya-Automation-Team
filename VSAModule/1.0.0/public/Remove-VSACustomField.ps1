function Remove-VSACustomField {
    <#
    .Synopsis
        Deletes an existing Custom field.
    .DESCRIPTION
        Deletes an existing Custom field.
        Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER FieldName
        Custom field name to selete.
    .EXAMPLE
        Remove-VSACustomField -FieldName 'FieldToDelete'
    .EXAMPLE
        Remove-VSACustomField -VSAConnection connection -FieldName 'FieldToDelete'
    .EXAMPLE
        Remove-VSACustomField -FieldName 'DeleteWithoutConfirmation' -Confirm:$false
    .INPUTS
        Accepts piped non-persistent VSAConnection 
    .OUTPUTS
        True if removing was successful
    #>
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High'
    )]
    param (
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/assetmgmt/assets/customfields/{0}",

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $FieldName
    )

    [hashtable]$Params =@{
        URISuffix = $($URISuffix -f $FieldName)
        Method    = 'DELETE'
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    if( $PSCmdlet.ShouldProcess( $FieldName ) ) {
        return Invoke-VSARestMethod @Params
    }
}
Export-ModuleMember -Function Remove-VSACustomField