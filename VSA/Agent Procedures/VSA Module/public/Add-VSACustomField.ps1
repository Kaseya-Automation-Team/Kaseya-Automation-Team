function Add-VSACustomField {
    <#
    .Synopsis
       Creates a custom field.
    .DESCRIPTION
       Creates a custom field of given type.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER FieldName
        Custom field's name.
    .PARAMETER FieldType
        New Field Type: "string", "number", "datetime", "date", "time".
    .EXAMPLE
       Add-VSACustomField -FieldName 'MyField'
    .EXAMPLE
       Add-VSACustomField -FieldName 'MyField' -FieldType datetime
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if creation was successful
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/assetmgmt/assets/customfields',

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $FieldName,

        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateSet("string", "number", "datetime", "date", "time")]
        [string]$FieldType = 'string'
        )

    [bool]$result = $false

    $Body = @(@{"key"="FieldName";"value"=$FieldName },@{ "key"="FieldType";"value"=$FieldType }) | ConvertTo-Json

    [hashtable]$Params = @{}
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    #[string[]]$ExistingFields = Get-VSACustomFields -Filter "FieldName eq `'$FieldName`'"
    [string[]]$ExistingFields = Get-VSACustomFields @Params | Select-Object -ExpandProperty FieldName 

    If ($FieldName -notin $ExistingFields) {
        
        $Params.Add('URISuffix', $URISuffix)
        $Params.Add('Method', 'POST')
        $Params.Add('Body', $Body)
        
        $result = Update-VSAItems @Params
    } else {
        $Message = "The custom field `'$FieldName`' already exists"
        Log-Event -Msg $Message -Id 4000 -Type "Error"
        throw $Message
    }
    return $result

    #Get-RequestData @requestParameters
}
Export-ModuleMember -Function Add-VSACustomField