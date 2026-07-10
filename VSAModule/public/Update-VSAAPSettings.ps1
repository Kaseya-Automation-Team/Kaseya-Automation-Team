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

    [CmdletBinding(SupportsShouldProcess)]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        # The live VSA Swagger (docs/v1.0) is authoritative and CONTRADICTS the public webhelp:
        # PUT /automation/agentprocs/quicklaunch/askbeforeexecuting/{value} requires BOTH the value
        # in the PATH ({value}, required) AND a flag query boolean (required). The earlier F-49b
        # change trusted the webhelp ("fact #6"), dropped the /{0} path token, and left only
        # ?flag={0} -- which matches no route. Restored: same boolean fills both slots (F-15).
        [string] $URISuffix = "api/v1.0/automation/agentprocs/quicklaunch/askbeforeexecuting/{0}?flag={0}",

        [Alias("AskBeforeExecuting")]
        [switch] $Flag
)
    process {
    
    return Invoke-VSAWriteRequest -Method 'PUT' -URISuffix ($( $URISuffix -f $Flag.ToString().ToLower() )) -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}

Export-ModuleMember -Function Update-VSAAPSettings