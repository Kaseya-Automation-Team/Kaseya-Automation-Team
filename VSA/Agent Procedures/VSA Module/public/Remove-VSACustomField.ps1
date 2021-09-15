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
        Update-VSACustomField -VSAConnection connection -FieldName 'FieldToDelete'
    .INPUTS
        Accepts piped non-persistent VSAConnection 
    .OUTPUTS
        True if removing was successful
    #>
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

    [hashtable]$Params =@{}

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    #[string[]]$ExistingFields = Get-VSACustomFields -Filter "FieldName eq `'$FieldName`'"
    [string[]]$ExistingFields = Get-VSACustomFields @Params | Select-Object -ExpandProperty FieldName 

    If ( $FieldName -in $ExistingFields ) {

        $Params.Add('URISuffix', $URISuffix)
        $Params.Add('Method', 'DELETE')
        $result = Update-VSAItems @Params
    } else {
        $Message = "The custom field `'$FieldName`' does not exist"
        Log-Event -Msg $Message -Id 4000 -Type "Error"
        throw $Message
    }
    return $result
}
Export-ModuleMember -Function Remove-VSACustomField