function Update-VSASDTicketPriority
{
    <#
    .Synopsis
       Updates the priority of a service desk ticket.
    .DESCRIPTION
       Updates the priority of a service desk ticket.
       Takes either persistent or non-persistent connection information.
    .PARAMETER VSAConnection
        Specifies existing non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER ServiceDeskTicketId
        Specifies id of service desk ticket
    .PARAMETER PriorityId
        Specifies id of the priority
    .EXAMPLE
       Update-VSASDTicketPriority -ServiceDeskTicketId 979868787875855 -PriorityId 3498242298
    .EXAMPLE
       Update-VSASDTicketPriority -VSAConnection $connection -ServiceDeskTicketId 979868787875855 -PriorityId 3498242298
    .INPUTS
       Accepts piped non-persistent VSAConnection
    .OUTPUTS
       True if successful
    #>

    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '', Justification = 'ShouldProcess is invoked centrally by Invoke-VSAWriteRequest, which receives this cmdlet''s $PSCmdlet via -Caller (module-wide pattern).')]
    param (
        [parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string] $URISuffix = "api/v1.0/automation/servicedesktickets/{0}/priority/{1}",

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
        })]
        [string] $PriorityId
)
    process {

    return Invoke-VSAWriteRequest -Method 'PUT' -URISuffix ($($URISuffix -f $ServiceDeskTicketId, $PriorityId)) -VSAConnection $VSAConnection -Caller $PSCmdlet
    }
}

Export-ModuleMember -Function Update-VSASDTicketPriority