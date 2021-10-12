function Add-VSASDTicketNotes
{
    <#
    .Synopsis
       Adds a note to a specified service desk ticket.
    .DESCRIPTION
       Adds a note to a specified service desk ticket.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER ServiceDeskTicketId
        Specifies id of service desk ticket
    .PARAMETER Hidden
        Specifies if note should be hidden
    .PARAMETER SystemFlag
        Specifies note will be owned by system or user
    .PARAMETER Text
        Specifies text of the note   
    .EXAMPLE
       Add-VSASDTicketNotes -ServiceDeskTicketId 979868787875855 -Text "this is test note" -SystemFlag -Hidden
    .EXAMPLE
       Add-VSASDTicketNotes -ServiceDeskTicketId 979868787875855 -Text "this is test note"
    .EXAMPLE
       Add-VSASDTicketNotes -VSAConnection $connection -ServiceDeskTicketId 979868787875855 -Text "this is test note"
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Success or failure
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
        [string] $URISuffix = "api/v1.0/automation/servicedesktickets/{0}/notes",
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $ServiceDeskTicketId,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$false)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [switch] $Hidden,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$false)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$false)]
        [ValidateNotNullOrEmpty()] 
        [switch] $SystemFlag,
        [parameter(ParameterSetName = 'Persistent', Mandatory=$true)]
        [parameter(ParameterSetName = 'NonPersistent', Mandatory=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Text
)
	
    $URISuffix = $URISuffix -f $ServiceDeskTicketId

    [hashtable]$Params =@{
        URISuffix = $URISuffix
        Method = 'POST'
    }

    $Body = ConvertTo-Json @{"Hidden"=$Hidden.ToBool(); "SystemFlag"=$SystemFlag.ToBool(); "Text"="$Text";}

    $Params.Add('Body', $Body)

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Update-VSAItems @Params
}

Export-ModuleMember -Function Add-VSASDTicketNotes