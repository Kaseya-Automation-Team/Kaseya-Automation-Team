function Remove-VSAInfoMsg
{
    <#
    .Synopsis
       Removes item from Inbox
    .DESCRIPTION
       Removes item from Inbox in Info Center
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER ID
        Specifies ID of message from Inbox
    .EXAMPLE
       Remove-VSAInfoMsg -ID 4324242342432
    .EXAMPLE
       Remove-VSAInfoMsg -VSAConnection $connection -ID 4324242342432
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
        [string] $URISuffix = "api/v1.0/infocenter/messages/{0}",
        [Parameter(ParameterSetName = 'Persistent', Mandatory = $true, ValueFromPipelineByPropertyName=$true)]
        [Parameter(ParameterSetName = 'NonPersistent', Mandatory = $true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [bigint] $ID
    )
    
    $URISuffix = $URISuffix -f $ID
     
    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'DELETE'
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Remove-VSAInfoMsg