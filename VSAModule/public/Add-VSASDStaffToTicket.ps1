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
    .PARAMETER Value
        Specifies new value of custom field
    .EXAMPLE
       Add-VSASDStaffToTicket -VSAConnection $connection -ServiceDeskTicketId 123 -StaffId 123
    .INPUTS
       Accepts established VSAConnection.
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
    #Remove empty keys
    foreach ( $key in $Params.Keys.Clone() ) {
        if ( -not $Params[$key] )  { $Params.Remove($key) }
    }

    return Invoke-VSARestMethod @Params
}
New-Alias -Name Add-VSASDStaff -Value Add-VSASDStaffToTicket
Export-ModuleMember -Function Add-VSASDStaffToTicket -Alias Add-VSASDStaff