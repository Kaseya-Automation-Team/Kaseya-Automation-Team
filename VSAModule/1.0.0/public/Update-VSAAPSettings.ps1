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
       Update-VSAAPSettings -Flag
    .EXAMPLE
       Update-VSAAPSettings -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if update was successful
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/automation/agentprocs/quicklaunch/askbeforeexecuting/{0}?flag={0}",

        [Alias("AskBeforeExecuting")]
        [switch] $Flag
)
    
    [hashtable]$Params =@{
        URISuffix = $( $URISuffix -f $Flag.ToString().ToLower() )
        Method = 'PUT'
    }
    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}

Export-ModuleMember -Function Update-VSAAPSettings