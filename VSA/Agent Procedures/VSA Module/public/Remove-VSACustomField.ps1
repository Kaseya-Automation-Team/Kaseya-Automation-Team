function Remove-VSACustomField {
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

    $URISuffix = $URISuffix -f $FieldName

    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'DELETE'
    }
    return Update-VSAItems @Params
}
Export-ModuleMember -Function Remove-VSACustomField