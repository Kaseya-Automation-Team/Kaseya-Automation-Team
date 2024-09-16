function New-VSASDTicketNote
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
       New-VSASDTicketNote -ServiceDeskTicketId 979868787875855 -Text "this is test note" -SystemFlag -Hidden
    .EXAMPLE
       New-VSASDTicketNote -ServiceDeskTicketId 979868787875855 -Text "this is test note"
    .EXAMPLE
       New-VSASDTicketNote -VSAConnection $connection -ServiceDeskTicketId 979868787875855 -Text "this is test note"
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       Success or failure
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/automation/servicedesktickets/{0}/notes",

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $ServiceDeskTicketId,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $Text,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)] 
        [switch] $Hidden,

        [parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [switch] $SystemFlag
)
	
    [string]$Body = ConvertTo-Json @{"Hidden"=$Hidden.ToBool(); "SystemFlag"=$SystemFlag.ToBool(); "Text"="$Text";} -Compress

    [hashtable]$Params =@{
        URISuffix = $($URISuffix -f $ServiceDeskTicketId)
        Method    = 'POST'
        Body      = $Body
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}

New-Alias -Name Add-VSASDTicketNotes -Value New-VSASDTicketNote
Export-ModuleMember -Function New-VSASDTicketNote -Alias Add-VSASDTicketNotes