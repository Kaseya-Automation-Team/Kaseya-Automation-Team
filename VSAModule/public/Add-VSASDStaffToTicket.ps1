function Add-VSASDStaffToTicket
{
    <#
    .Synopsis
        Assigns a staff record to a service desk ticket.
    .DESCRIPTION
        Assigns a staff record to a service desk ticket.
    .PARAMETER VSAConnection
        Specifies an non-persistent VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER ServiceDeskTicketId
        Specifies id of service desk ticket
    .PARAMETER StaffId
        Specifies an Id of Service Desk staff
    .EXAMPLE
       Add-VSASDStaffToTicket -VSAConnection $connection -ServiceDeskTicketId 123 -StaffId 123
    .INPUTS
       Accepts established VSAConnection.
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
        [string] $URISuffix = "api/v1.0/automation/servicedesks/assign/{0}/{1}",

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $ServiceDeskTicketId,

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({
            if( $_ -notmatch "^\d+$" ) {
                throw "Non-numeric Id"
            }
            return $true
        })]
        [string] $StaffId
)

    return Invoke-VSAWriteRequest -Method 'PUT' -URISuffix ($($URISuffix -f $ServiceDeskTicketId, $StaffId)) -VSAConnection $VSAConnection -Caller $PSCmdlet
}
New-Alias -Name Add-VSASDStaff -Value Add-VSASDStaffToTicket
Export-ModuleMember -Function Add-VSASDStaffToTicket -Alias Add-VSASDStaff