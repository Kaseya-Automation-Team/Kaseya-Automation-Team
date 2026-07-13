function Start-VSAAPReturnId
{
    <#
    .Synopsis
       Runs an agent procedure now and returns the execution id.
    .DESCRIPTION
       Runs an agent procedure on an agent immediately and returns the id of the resulting execution,
       so the run can be tracked. Optionally supplies script prompt responses and a callback URL.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AgentId
        Specifies the agent id to run the procedure on.
    .PARAMETER AgentProcedureId
        Specifies the agent procedure id to run.
    .PARAMETER ScriptPrompts
        Specifies an array of script prompt responses.
    .PARAMETER CallbackUrl
        Specifies a URL the server calls back when the procedure completes.
    .EXAMPLE
       Start-VSAAPReturnId -AgentId 123456789 -AgentProcedureId 3535753
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       The execution id of the started procedure.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = 'api/v1.0/automation/agentprocs/{0}/{1}/runnowgetid',

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({ if ($_ -notmatch "^\d+$") { throw "Non-numeric Id" } return $true })]
        [string] $AgentId,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateScript({ if ($_ -notmatch "^\d+$") { throw "Non-numeric Id" } return $true })]
        [string] $AgentProcedureId,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [object[]] $ScriptPrompts,

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string] $CallbackUrl
    )
    process {
        $URISuffix = $URISuffix -f $AgentId, $AgentProcedureId
        [hashtable] $BodyHT = @{}
        if ($PSBoundParameters.ContainsKey('ScriptPrompts')) { $BodyHT['ScriptPrompts'] = @($ScriptPrompts) }
        if (-not [string]::IsNullOrEmpty($CallbackUrl))       { $BodyHT['CallbackUrl']   = $CallbackUrl }
        return Invoke-VSAWriteRequest -Body $BodyHT -Method PUT -URISuffix $URISuffix `
            -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}
Export-ModuleMember -Function Start-VSAAPReturnId
