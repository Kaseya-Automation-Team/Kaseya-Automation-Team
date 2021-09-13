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

    [bool]$result = $false

    
    $URISuffix = $URISuffix -f $FieldName

    [hashtable]$Params =@{
            URISuffix = $URISuffix
            Method = 'DELETE'
        }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    #[string[]]$ExistingFields = Get-VSACustomFields -Filter "FieldName eq `'$FieldName`'"
    [string[]]$ExistingFields = Get-VSACustomFields | Select-Object -ExpandProperty FieldName 

    If ($FieldName -in $ExistingFields)
    {
        $result = Update-VSAItems @Params
    }
    return $result
}
Export-ModuleMember -Function Remove-VSACustomField