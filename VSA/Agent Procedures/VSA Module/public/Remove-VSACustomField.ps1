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
        [string] $URISuffix = "api/v1.0/assetmgmt/assets/customfields/{0}",

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'NonPersistent')]
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'Persistent')]
        [ValidateNotNullOrEmpty()] 
        [string] $FieldName
        )

    [bool]$result = $false

    
    $URISuffix = $URISuffix -f $FieldName

    [hashtable]$Params =@{
                            'URISuffix' = $URISuffix
                            'Method'    = 'DELETE'
                        }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    if( $PSCmdlet.ShouldProcess( $FieldName ) ) {
        return Update-VSAItems @Params
    }
}
Export-ModuleMember -Function Remove-VSACustomField