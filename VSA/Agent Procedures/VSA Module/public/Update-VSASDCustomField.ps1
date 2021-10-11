function Update-VSASDTicketCustomFields
{
    <#
    .Synopsis
       Updates the value of a custom field in a service desk ticket
    .DESCRIPTION
       Updates the value of a custom field in a service desk ticket.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER ServiceDeskTicketId
        Specifies id of service desk ticket
    .PARAMETER CustomFieldId
        Specifies id of customer field
    .PARAMETER Value
        Specifies new value of custom field
    .EXAMPLE
       Update-VSASDTicketCustomFields -ServiceDeskTicketId 3256598065654 -CustomFieldId 376887433552 -Value "Automatic"
    .EXAMPLE
       Update-VSASDTicketCustomFields -VSAConnection $connection -ServiceDeskTicketId 3256598065654 -CustomFieldId "Automatic"
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
        [string] $URISuffix = "api/v1.0/automation/servicedesktickets/{0}/customfields/{1}",
        [ValidateNotNullOrEmpty()]
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $ServiceDeskTicketId,
        [ValidateNotNullOrEmpty()]
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $CustomFieldId,
        [ValidateNotNullOrEmpty()]
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Value
)
    
    $URISuffix = $URISuffix -f $ServiceDeskTicketId, $CustomFieldId

    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'PUT'
    }

	$Body = ConvertTo-Json "$Value"
	
    $Params.Add('Body', $Body)

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    Write-Host $Body

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Update-VSASDTicketCustomFields