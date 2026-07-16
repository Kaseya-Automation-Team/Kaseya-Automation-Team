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
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is invoked centrally by Invoke-VSAWriteRequest, which receives this cmdlet''s $PSCmdlet via -Caller (module-wide pattern).')]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
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
    process {

    # The previous body was a hand-rolled here-string with unescaped {0}/{1} substitutions and a
    # trailing comma before the closing ']' (invalid JSON per RFC 8259) (F-40). ConvertTo-Json
    # produces valid, correctly escaped JSON.
    $Body = ConvertTo-Json @(
        @{ key = 'FieldName'; value = $FieldName }
        @{ key = 'FieldType'; value = $FieldType }
    ) -Compress

    return Invoke-VSAWriteRequest -Body ($Body) -Method 'POST' -URISuffix ($URISuffix) -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
New-Alias -Name Add-VSACustomField -Value New-VSACustomField
Export-ModuleMember -Function New-VSACustomField -Alias Add-VSACustomField
