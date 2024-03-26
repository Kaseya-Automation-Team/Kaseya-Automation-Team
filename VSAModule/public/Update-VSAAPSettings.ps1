function Update-VSAAPSettings
{
    <#
    .Synopsis
       Updates value of "Ask before executing" settings.
    .DESCRIPTION
       Sets the value of the 'Ask before executing' checkbox on the Quick View dialog.
       This checkbox is set individually for each VSA user and is applied only when running a quicklaunch agent procedure..
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies id of the agent machine
    .EXAMPLE
       Update-VSAAPSettings -Flag true
    .EXAMPLE
       Update-VSAAPSettings -VSAConnection $connection -Flag false
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       No output
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
        [string] $URISuffix = "api/v1.0/automation/agentprocs/quicklaunch/askbeforeexecuting/{0}?flag={0}",
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Flag
)
    
    $URISuffix = $URISuffix -f $Flag
    
    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'PUT'
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Update-VSAAPSettings