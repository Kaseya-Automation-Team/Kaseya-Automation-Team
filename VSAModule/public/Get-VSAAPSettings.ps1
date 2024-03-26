function Get-VSAAPSettings {
    <#
    .Synopsis
       Returns value of "Ask before executing" settings.
    .DESCRIPTION
       Returns the setting for the 'Ask before executing' checkbox on the Quick View dialog.
       This checkbox is set individually for each VSA user and is applied only when running a quicklaunch agent procedure.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .EXAMPLE
       Get-VSAAPSettings
    .EXAMPLE
       Get-VSAAPSettings -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       Value of settings - true or false
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
        [string] $URISuffix = "api/v1.0/automation/agentprocs/quicklaunch/askbeforeexecuting"
    )

    [hashtable]$Params =@{
        URISuffix = $URISuffix
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}


    return Get-VSAItems @Params
}
Export-ModuleMember -Function Get-VSAAPSettings