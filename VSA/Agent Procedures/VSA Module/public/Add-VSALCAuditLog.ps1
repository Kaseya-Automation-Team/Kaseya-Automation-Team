function Add-VSALCAuditLog
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
       Add-VSALCAuditLog -AgentId "34543554343" -Message "text"
	.EXAMPLE
       Add-VSALCAuditLog -AgentId "34543554343" -Message "text" -AgentName "Sample agent" -UserName "Sample user"
    .EXAMPLE
       Add-VSALCAuditLog -VSAConnection $connection
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
        [string] $URISuffix = "api/v1.0/assetmgmt/agent/{0}/KLCAuditLogEntry",
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $AgentId,
		[parameter(ParameterSetName = 'Persistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $UserName = "VSAModule",
		[parameter(ParameterSetName = 'Persistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $AgentName = "VSAModule",
		[parameter(ParameterSetName = 'Persistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Message
    )
	
	$URISuffix = $URISuffix -f $AgentId
     
    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'PUT'
    }

    #$Body = "{[$ID]}"
	$Body = ConvertTo-Json @{"UserName"="$UserName";"AgentName"="$AgentName";"LogMessage"="$Message" }
    Write-Host $Body
    $Params.Add('Body', $Body)

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Add-VSALCAuditLog