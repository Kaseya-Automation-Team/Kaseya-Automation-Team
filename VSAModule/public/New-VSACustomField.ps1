function New-VSACustomField {
    <#
    .Synopsis
       Creates a custom field.
    .DESCRIPTION
       Creates a custom field of given type.
    .PARAMETER VSAConnection
        Specifies an established VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER FieldName
        Custom field's name.
    .PARAMETER FieldType
        New Field Type: "string", "number", "datetime", "date", "time".
    .EXAMPLE
       New-VSACustomField -VSAConnection $VSAConnection -FieldName 'MyField'
    .EXAMPLE
       New-VSACustomField -VSAConnection $VSAConnection -FieldName 'MyField' -FieldType datetime
    .INPUTS
       Accepts piped VSAConnection 
    .OUTPUTS
       True if creation was successful
    .NOTES
        Version 0.1.1
    #>
    [alias("Add-VSACustomField")]
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/assetmgmt/assets/customfields',

        [Alias("Name")]
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $FieldName,

        [Alias("Type")]
        [parameter(Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateSet("string", "number", "datetime", "date", "time")]
        [string]$FieldType = 'string'
        )

    [bool]$result = $false

    #[string[]]$ExistingFields = Get-VSACustomFields -Filter "FieldName eq `'$FieldName`'"
    [string[]]$ExistingFields = Get-VSACustomFields -VSAConnection $VSAConnection | Select-Object -ExpandProperty FieldName 

    If ($FieldName -notin $ExistingFields) {
        
        $Body = @'
[
    {{
        "key": "FieldName",
        "value": "{0}"
    }},
    {{
        "key": "FieldType",
        "value": "{1}"
    }},
]
'@ -f $FieldName, $FieldType

        [hashtable]$Params = @{
            VSAConnection  = $VSAConnection
            URISuffix      = $URISuffix
            Method         = 'POST'
            Body           = $Body
        }
        
        $result = Invoke-VSARestMethod @Params
    } else {
        Write-Warning "New-VSACustomField: the custom field `'$FieldName`' already exists."
    }
    return $result
}
Export-ModuleMember -Function New-VSACustomField