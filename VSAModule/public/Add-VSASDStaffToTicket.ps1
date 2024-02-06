function Add-VSASDStaffToTicket
{
    <#
    .Synopsis
        Assigns a staff record to a service desk ticket.
    .DESCRIPTION
        Assigns a staff record to a service desk ticket.
    .PARAMETER VSAConnection
        Specifies an established VSAConnection.
    .PARAMETER URISuffix
        Specifies URI suffix if it differs from the default.
    .PARAMETER ServiceDeskTicketId
        Specifies id of service desk ticket
    .PARAMETER StaffId
        Specifies an Id of Service Desk staff
    .PARAMETER Value
        Specifies new value of custom field
    .EXAMPLE
       Add-VSASDStaffToTicket -VSAConnection $connection -ServiceDeskTicketId 123 -StaffId 123
    .INPUTS
       Accepts established VSAConnection.
    .OUTPUTS
       No output
    #>
    [alias("Add-VSASDStaff")]
    [CmdletBinding()]
    param ( 
        [parameter(Mandatory = $true, 
            ValueFromPipelineByPropertyName = $true)]
        [VSAConnection] $VSAConnection,

        [parameter(DontShow, Mandatory=$false,
            ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $URISuffix = "api/v1.0/automation/servicedesks/assign/{0}/{1}",

        [ValidateNotNullOrEmpty()]
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $ServiceDeskTicketId,

        [ValidateNotNullOrEmpty()]
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()] 
        [string] $StaffId
)
    
    $URISuffix = $URISuffix -f $ServiceDeskTicketId, $StaffId

    [hashtable]$Params =@{
        VSAConnection = $VSAConnection
        URISuffix     = $URISuffix
        Method        = 'PUT'
    }

    return Invoke-VSARestMethod @Params
}

Export-ModuleMember -Function Add-VSASDStaffToTicket