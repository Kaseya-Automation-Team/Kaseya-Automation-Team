function Update-VSASDTicketStatus
{
    <#
    .Synopsis
       Updates the status of a service desk ticket.
    .DESCRIPTION
       Updates the status of a service desk ticket.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER ServiceDeskTicketId
        Specifies recepient's email address
    .PARAMETER StatusId
        Specifies email address of sender
    .EXAMPLE
       Update-VSASDTicketStatus -ServiceDeskTicketId 979868787875855 -StatusId 434907986
    .EXAMPLE
       Update-VSASDTicketStatus -VSAConnection $connection -ServiceDeskTicketId 979868787875855 -StatusId 434907986
    .INPUTS
       Accepts piped non-persistent VSAConnection 
    .OUTPUTS
       True if successful
    #>

    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $false, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/automation/servicedesktickets/{0}/status/{1}",

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
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })] $StatusId
)

    [hashtable]$Params =@{
        URISuffix = $($URISuffix -f $ServiceDeskTicketId, $StatusId)
        Method = 'PUT'
    }

    if($VSAConnection) {$Params.Add('VSAConnection', $VSAConnection)}

    return Invoke-VSARestMethod @Params
}

Export-ModuleMember -Function Update-VSASDTicketStatus