function Update-VSACustomField
{
    <#
    .Synopsis
       Updates an existing Custom field.
    .DESCRIPTION
       Renames VSA an custom field or changes value of the field of an agent.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER FieldName
        Custom field name to rename or change value.
    .PARAMETER FieldValue
        Value to assign to the provided field for provided AgentID.
    .PARAMETER NewFieldName
        New Field Name.
    .EXAMPLE
       Update-VSACustomField -FieldName 'MyField' -FieldValue 'New Value' -AgentID '100001'
    .EXAMPLE
       Update-VSACustomField -FieldName 'OldFieldName' -NewFieldName 'NewFieldName'
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if update was successful
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'RenameField')]
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'UpdateValue')]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'RenameField')]
        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'UpdateValue')]
        [ValidateNotNullOrEmpty()] 
        [string] $FieldName,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'RenameField')]
        [ValidateScript(
            {
                if ( -not [string]::IsNullOrEmpty($_) -and ($FieldName -ne $_) ) {$true}
                else {$Message = "Cannot rename the field `'$FieldName`' to `'$_`'"; Log-Event -Msg $Message -Id 4000 -Type "Error"; throw $Message}
            })]
        [string] $NewFieldName,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'UpdateValue')]
        [ValidateNotNullOrEmpty()] 
        [string] $FieldValue,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            ParameterSetName = 'UpdateValue')]
        [ValidateNotNullOrEmpty()] 
        [string] $AgentID,

        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'RenameField')]
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'UpdateValue')]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/assetmgmt/assets/{1}/customfields/{0}"
        )

    [string]  $Body
    [string[]]$Values = @($FieldName) # Array of values to actualize URI suffix.  The first element of array is the field name. 

    if ( [string]::IsNullOrEmpty($AgentID) ) { # AgentID is not set. Field renaming
        
        $Values += '' # The second element of array to actualize URI suffix is an empty string if agent ID is not provided.
        $Body = ConvertTo-Json @(@{"key"="NewFieldName";"value"=$NewFieldName})

    } else {                                  # Field value updating
        $Values += '$AgentID'
        $Body = ConvertTo-Json @(@{"key"="FieldValue";"value"=$FieldValue })
    }
    $Values | Out-String | Write-Verbose
    $Body | Write-Verbose
    
    $URISuffix = $($URISuffix -f $Values) -replace '//', '/' # URI suffix actualization
    $URISuffix | Write-Verbose

    [hashtable]$Params =@{
    URISuffix = $URISuffix
    Method = 'PUT'
    Body = $Body
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    [string[]]$ExistingFields = Get-VSACustomFields | Select-Object -ExpandProperty FieldName

    If ( $FieldName -notin $ExistingFields ) {
        $Message = "The custom field `'$FieldName`' does not exist"
        Log-Event -Msg $Message -Id 4000 -Type "Error"
        throw $Message
    }

    if ( $NewFieldName -in $ExistingFields ) {
        $Message = "Cannot rename `'$FieldName`' to `'$NewFieldName`'. The custom field name `'$NewFieldName`' already exists"
        Log-Event -Msg $Message -Id 4000 -Type "Error"
        throw $Message
    }

    return Update-VSAItems @Params
        
}
Export-ModuleMember -Function Update-VSACustomField