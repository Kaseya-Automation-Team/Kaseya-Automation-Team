function New-VSALCAuditLog
{
    <#
    .Synopsis
       Adds entry to agent's Live Connect audit log
    .DESCRIPTION
       Adds new entry to Live Connect audit log on specified agent machine.
	   If username and agentname are not specified, default value "VSAModule" will be used.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER AgentId
        Specifies numeric id of agent machine
    .PARAMETER UserName
        Specifies username shown in Live Connect log. Defaults to 'VSAModule' when not supplied.
    .PARAMETER AgentName
        Specifies agentname shown in Live Connect log. Defaults to 'VSAModule' when not supplied.
        The server rejects the request with "Invalid AgentName" if this field is null, so it is
        always sent (F-1).
    .PARAMETER Message
        Required parameter which specifies text message shown in Live Connect log
    .EXAMPLE
       New-VSALCAuditLog -AgentId "34543554343" -Message "text"
	.EXAMPLE
       New-VSALCAuditLog -AgentId "34543554343" -Message "text" -AgentName "Sample agent" -UserName "Sample user"
    .EXAMPLE
       New-VSALCAuditLog -VSAConnection $connection
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       No output
    #>

    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is invoked centrally by Invoke-VSAWriteRequest, which receives this cmdlet''s $PSCmdlet via -Caller (module-wide pattern).')]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = "api/v1.0/assetmgmt/agent/{0}/KLCAuditLogEntry",

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $AgentId,

		[Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $UserName = 'VSAModule',

        # The API rejects a null AgentName with HTTP 400 "Invalid AgentName", so this must always be
        # sent. Defaulting it here implements the behaviour the help has always documented and keeps
        # the documented one-argument call (-AgentId + -Message) working (F-1).
		[Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $AgentName = 'VSAModule',

		[Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string] $Message
    )
    process {

	$URISuffix = $URISuffix -f $AgentId

    return Invoke-VSAWriteRequest -Body ($(ConvertTo-Json @{'UserName'=$UserName;'AgentName'=$AgentName;'LogMessage'=$Message })) -Method 'PUT' -URISuffix ($URISuffix) -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}

New-Alias -Name Add-VSALCAuditLog -Value New-VSALCAuditLog
Export-ModuleMember -Function New-VSALCAuditLog -Alias Add-VSALCAuditLog