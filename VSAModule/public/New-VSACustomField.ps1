function New-VSACustomField {
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
       New-VSACustomField -FieldName 'MyField'
    .EXAMPLE
       New-VSACustomField -FieldName 'MyField' -FieldType datetime
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if creation was successful
    .NOTES
        Version 0.1.0
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory = $false, 
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

    [string[]]$ExistingFields = Get-VSACustomFields -VSAConnection $VSAConnection | Select-Object -ExpandProperty FieldName 

    if ($FieldName -notin $ExistingFields) {
        
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

        #Remove empty keys
        foreach ( $key in $Params.Keys.Clone() ) {
            if ( -not $Params[$key] )  { $Params.Remove($key) }
        }
        
        $result = Invoke-VSARestMethod @Params
    } else {
        Write-Warning "New-VSACustomField: the custom field `'$FieldName`' already exists."
    }
    return $result
}
New-Alias -Name Add-VSACustomField -Value New-VSACustomField
Export-ModuleMember -Function New-VSACustomField -Alias Add-VSACustomField