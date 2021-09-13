function Add-VSACustomField {
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
        [string] $URISuffix = 'api/v1.0/assetmgmt/assets/customfields',
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'NonPersistent')]
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'Persistent')]
        [ValidateNotNullOrEmpty()] 
        [string] $FieldName,
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'NonPersistent')]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'Persistent')]
        [ValidateSet("string", "number", "datetime", "date", "time")]
        [string]$FieldType = 'string'
        )

    [bool]$result = $false

    $Body = @(@{"key"="FieldName";"value"=$FieldName },@{ "key"="FieldType";"value"=$FieldType }) | ConvertTo-Json

    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'POST'
        Body = $Body
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    #[string[]]$ExistingFields = Get-VSACustomFields -Filter "FieldName eq `'$FieldName`'"
    [string[]]$ExistingFields = Get-VSACustomFields | Select-Object -ExpandProperty FieldName 

    If ($FieldName -notin $ExistingFields)
    {
        $result = Update-VSAItems @Params
    }
    return $result

    #Get-RequestData @requestParameters
}
Export-ModuleMember -Function Add-VSACustomField