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
        Specifies username shown in Live Connect log
    .PARAMETER AgentName
        Specifies agentname shown in Live Connect log
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

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
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
        [string] $UserName,

		[Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $AgentName,

		[Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Message
    )
	
	$URISuffix = $URISuffix -f $AgentId
     
    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'PUT'
        Body = $(ConvertTo-Json @{'UserName'=$UserName;'AgentName'=$AgentName;'LogMessage'=$Message })
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}

New-Alias -Name Add-VSALCAuditLog -Value New-VSALCAuditLog
Export-ModuleMember -Function New-VSALCAuditLog -Alias Add-VSALCAuditLog